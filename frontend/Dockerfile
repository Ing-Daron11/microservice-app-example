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

# Crear directorios con permisos correctos antes de cambiar usuario
RUN mkdir -p /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
    && chown -R nginx:nginx /var/cache/nginx \
    && chmod -R 755 /var/cache/nginx

# Directorio de Nginx
WORKDIR /usr/share/nginx/html

# Limpiar contenido por defecto
RUN rm -rf ./*

# Copiar archivos generados del builder
COPY --from=builder /app/dist . 

# Ajustar permisos de los archivos servidos
RUN chown -R nginx:nginx /usr/share/nginx/html

# Crear configuración personalizada para nginx
RUN echo 'server {' > /etc/nginx/conf.d/default.conf \
    && echo '    listen 80;' >> /etc/nginx/conf.d/default.conf \
    && echo '    server_name localhost;' >> /etc/nginx/conf.d/default.conf \
    && echo '    root /usr/share/nginx/html;' >> /etc/nginx/conf.d/default.conf \
    && echo '    index index.html;' >> /etc/nginx/conf.d/default.conf \
    && echo '    location / {' >> /etc/nginx/conf.d/default.conf \
    && echo '        try_files $uri $uri/ /index.html;' >> /etc/nginx/conf.d/default.conf \
    && echo '    }' >> /etc/nginx/conf.d/default.conf \
    && echo '}' >> /etc/nginx/conf.d/default.conf

# Exponer puerto
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Comando por defecto (nginx debe ejecutarse como root para crear los directorios temporales)
CMD ["nginx", "-g", "daemon off;"]

