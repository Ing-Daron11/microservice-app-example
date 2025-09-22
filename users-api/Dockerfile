# Stage 1: Build stage con imagen Maven más nueva
FROM maven:3.9.5-amazoncorretto-8 AS builder
WORKDIR /app

# Copiar pom.xml primero para cachear dependencias
COPY pom.xml .

# Descargar dependencias (se cachea si no cambia pom.xml)
RUN mvn dependency:go-offline -B

# Copiar código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime stage
FROM amazoncorretto:8-alpine AS runtime
WORKDIR /app

# Instalar herramientas básicas para debugging y curl
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

# Healthcheck usando el endpoint /users/health que ya está configurado sin JWT
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8083/users/health || exit 1

# Variables de entorno por defecto
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SERVER_PORT=8083
ENV JWT_SECRET=myfancysecret

# Comando para ejecutar la aplicación
CMD java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar