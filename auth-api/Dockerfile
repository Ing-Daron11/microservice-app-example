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

# Certificados para llamadas HTTPS y curl
RUN apk --no-cache add ca-certificates curl

WORKDIR /root/

# Copiar el binario compilado
COPY --from=builder /app/auth-api .

# Variables de entorno - Container Apps usan puerto 80
ENV AUTH_API_PORT=80 \
    USERS_API_ADDRESS=http://microapp-dev-users-api-ca:80 \
    JWT_SECRET=myfancysecret

# Exponer el puerto 80 para Container Apps
EXPOSE 80

# Healthcheck usando puerto 80
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=5 \
  CMD curl -f http://localhost:80/version || exit 1

CMD ["./auth-api"]