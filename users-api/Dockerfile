# Stage 1: Build stage
FROM maven:3.8.6-openjdk-8-slim AS builder
WORKDIR /app

# Copiar archivos de configuración Maven
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .
COPY mvnw.cmd .

# Descargar dependencias (se cachea si no cambia pom.xml)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copiar código fuente y compilar
COPY src ./src
RUN ./mvnw clean package -DskipTests -B

# Stage 2: Runtime stage
FROM openjdk:8-jre-alpine AS runtime
WORKDIR /app

# Instalar herramientas básicas para debugging
RUN apk add --no-cache curl

# Crear usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar JAR desde build stage
COPY --from=builder /app/target/users-api-*.jar app.jar

# Cambiar ownership del JAR
RUN chown appuser:appgroup app.jar

USER appuser

# Puerto que usa la aplicación
EXPOSE 8083

# Healthcheck usando Spring Boot Actuator endpoint o endpoint básico
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8083/users/ || exit 1

# Variables de entorno por defecto
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SERVER_PORT=8083
ENV JWT_SECRET=myfancysecret

# Comando para ejecutar la aplicación
CMD java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar