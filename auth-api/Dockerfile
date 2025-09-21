# Build stage
FROM golang:1.18-alpine AS builder

WORKDIR /app

# Instalar dependencias de compilación
RUN apk add --no-cache git

# Copiar el código fuente
COPY . .

# Inicializar go modules y descargar dependencias
RUN go mod init auth-api && go mod tidy

# Compilar la aplicación
RUN go build -o auth-api .

# Production stage
FROM alpine:3.17

# Certificados para llamadas HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copiar el binario compilado
COPY --from=builder /app/auth-api .

# Variables de entorno (por defecto, se pueden sobreescribir en docker-compose)
ENV AUTH_API_PORT=8080 \
    USERS_API_ADDRESS=http://users-api:8080 \
    JWT_SECRET=PRFT

EXPOSE 8080

CMD ["./auth-api"]

