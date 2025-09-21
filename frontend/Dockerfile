# Multi-stage build para optimizar la imagen final
FROM node:18-alpine AS deps
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Stage 2: Build
FROM node:18-alpine AS builder
WORKDIR /app

# Copiar dependencias ya instaladas
COPY --from=deps /app/node_modules ./node_modules
# Copiar código fuente
COPY . .

# Build para producción
RUN npm run build

# Stage 3: Production con nginx simple
FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html

# Remover archivos por defecto de nginx
RUN rm -rf ./*

# Copiar archivos buildados
COPY --from=builder /app/dist .

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs && adduser -S nginx -u 1001 -G nodejs

# Cambiar ownership
RUN chown -R nginx:nodejs /usr/share/nginx/html
RUN chown -R nginx:nodejs /var/cache/nginx
RUN chown -R nginx:nodejs /var/log/nginx
RUN touch /var/run/nginx.pid
RUN chown -R nginx:nodejs /var/run/nginx.pid

USER nginx

# Puerto por defecto
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Comando por defecto
CMD ["nginx", "-g", "daemon off;"]