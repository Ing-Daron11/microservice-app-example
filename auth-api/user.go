package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	jwt "github.com/dgrijalva/jwt-go"
	"github.com/sony/gobreaker"
)

var (
	// ErrCircuitBreakerOpen indica que el Circuit Breaker está abierto y no se puede autenticar
	ErrCircuitBreakerOpen = errors.New("circuit breaker is open - authentication service unavailable")
)

var allowedUserHashes = map[string]interface{}{
	"admin_admin": nil,
	"johnd_foo":   nil,
	"janed_ddd":   nil,
}

// NewCircuitBreaker crea un Circuit Breaker configurado para llamadas a users-api
func NewCircuitBreaker() *gobreaker.CircuitBreaker {
	var settings gobreaker.Settings
	settings.Name = "users-api-breaker"
	settings.MaxRequests = 3
	settings.Interval = 60 * time.Second
	settings.Timeout = 30 * time.Second

	// ReadyToTrip cuando 50% de las últimas 5 solicitudes fallen
	settings.ReadyToTrip = func(counts gobreaker.Counts) bool {
		failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
		return counts.Requests >= 5 && failureRatio >= 0.5
	}
	
	// Callbacks para logging de demo y seguridad
	settings.OnStateChange = func(name string, from gobreaker.State, to gobreaker.State) {
		log.Printf("Circuit Breaker '%s' cambió estado: %s -> %s", name, from, to)
		
		// Log especial de seguridad cuando se abre el breaker
		if to == gobreaker.StateOpen {
			log.Printf("SECURITY ALERT: Circuit Breaker '%s' ABIERTO - Todos los logins serán DENEGADOS hasta que users-api se recupere", name)
		}
		
		// Log cuando se cierra y vuelve la normalidad
		if to == gobreaker.StateClosed {
			log.Printf("SECURITY: Circuit Breaker '%s' CERRADO - Logins normales restaurados", name)
		}
	}
	
	return gobreaker.NewCircuitBreaker(settings)
}

type User struct {
	Username  string `json:"username"`
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
	Role      string `json:"role"`
}

type HTTPDoer interface {
	Do(req *http.Request) (*http.Response, error)
}

type UserService struct {
	Client            HTTPDoer
	UserAPIAddress    string
	AllowedUserHashes map[string]interface{}
	CircuitBreaker    *gobreaker.CircuitBreaker
}

func (h *UserService) Login(ctx context.Context, username, password string) (User, error) {
	user, err := h.getUser(ctx, username)
	if err != nil {
		return user, err
	}

	userKey := fmt.Sprintf("%s_%s", username, password)

	if _, ok := h.AllowedUserHashes[userKey]; !ok {
		return user, ErrWrongCredentials
	}

	return user, nil
}

func (h *UserService) getUser(ctx context.Context, username string) (User, error) {
	var user User

	// Usar Circuit Breaker para proteger la llamada a users-api
	result, err := h.CircuitBreaker.Execute(func() (interface{}, error) {
		return h.getUserFromAPI(ctx, username)
	})

	if err != nil {
		// Si el Circuit Breaker está abierto, denegar el login por seguridad
		if err == gobreaker.ErrOpenState {
			log.Printf("SECURITY: Circuit Breaker ABIERTO - denegando login para '%s' por seguridad", username)
			return user, ErrCircuitBreakerOpen
		} else {
			log.Printf("Error llamando users-api para '%s': %s - denegando login", username, err.Error())
			return user, ErrCircuitBreakerOpen
		}
	}

	// Si todo fue bien, usar los datos completos del usuario
	user = result.(User)
	log.Printf("✅ Datos completos obtenidos de users-api para '%s'", username)
	return user, nil
}

// getUserFromAPI hace la llamada HTTP real a users-api (separada para el Circuit Breaker)
func (h *UserService) getUserFromAPI(ctx context.Context, username string) (User, error) {
	var user User

	token, err := h.getUserAPIToken(username)
	if err != nil {
		return user, err
	}
	
	log.Printf("🔗 Generando JWT token para llamar users-api con usuario '%s'", username)
	
	url := fmt.Sprintf("%s/users/%s", h.UserAPIAddress, username)
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Add("Authorization", "Bearer "+token)

	req = req.WithContext(ctx)

	resp, err := h.Client.Do(req)
	if err != nil {
		return user, fmt.Errorf("error de conexión a users-api: %w", err)
	}

	defer resp.Body.Close()
	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return user, fmt.Errorf("error leyendo respuesta de users-api: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return user, fmt.Errorf("users-api respondió con error %d: %s", resp.StatusCode, string(bodyBytes))
	}

	err = json.Unmarshal(bodyBytes, &user)
	if err != nil {
		return user, fmt.Errorf("error parseando respuesta JSON de users-api: %w", err)
	}

	return user, nil
}

func (h *UserService) getUserAPIToken(username string) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)
	claims := token.Claims.(jwt.MapClaims)
	claims["username"] = username
	claims["scope"] = "read"
	claims["iat"] = time.Now().Unix()
	claims["exp"] = time.Now().Add(time.Hour * 24).Unix() // Token expires in 24 hours
	return token.SignedString([]byte(jwtSecret))
}
