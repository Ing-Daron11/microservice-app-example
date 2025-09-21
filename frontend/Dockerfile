# ============================================================
# Stage 1: Build (con Node antiguo para compatibilidad)
# ============================================================
FROM node:8.17.0 AS builder

# Set working directory
WORKDIR /app

# Copiar package.json e instalar dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto del código fuente
COPY . .

# Build del frontend
RUN npm run build

# ============================================================
# Stage 2: Producción (servir con Nginx)
# ============================================================
FROM nginx:alpine AS production

# Directorio de Nginx
WORKDIR /usr/share/nginx/html

# Limpiar contenido por defecto
RUN rm -rf ./*

# Copiar archivos generados del builder
COPY --from=builder /app/dist . 

# Copiar configuración de Nginx si la necesitas (opcional)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Ajustar permisos usando el usuario ya existente 'nginx'
RUN chown -R nginx:nginx /usr/share/nginx/html

USER nginx

# Exponer puerto
EXPOSE 80

# Healthcheck (opcional)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Comando por defecto
CMD ["nginx", "-g", "daemon off;"]

