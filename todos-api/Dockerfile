# Stage 1: dependencias (usar package-lock si existe)
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
# npm ci es reproducible; si no hay package-lock, npm install
RUN if [ -f package-lock.json ]; then npm ci --only=production; else npm install --only=production; fi

# Stage 2: builder (por si hay build scripts - p.e. TypeScript)
FROM node:20-alpine AS builder
WORKDIR /app
COPY . .
# copiar node_modules ya instaladas (optimiza)
COPY --from=deps /app/node_modules ./node_modules
# Ejecutar build si existe el script "build" en package.json
RUN if grep -q "\"build\"" package.json; then npm run build || true; fi

# Stage 3: runtime pequeño
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
# copiar app + node_modules
COPY --from=builder /app .
COPY --from=deps /app/node_modules ./node_modules

# Instalar curl para healthcheck
RUN apk add --no-cache curl

# Crear usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Cambiar ownership de archivos al nuevo usuario
RUN chown -R appuser:appgroup /app

USER appuser

# Puerto esperado por la aplicación
EXPOSE 8082

# Healthcheck usando el endpoint /health que no requiere autenticación
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8082/health || exit 1

# Ejecutar en producción sin nodemon
CMD ["node", "server.js"]