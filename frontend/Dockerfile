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

# Crear configuración personalizada para nginx con proxy reverse
RUN echo 'server {' > /etc/nginx/conf.d/default.conf \
    && echo '    listen 80;' >> /etc/nginx/conf.d/default.conf \
    && echo '    server_name localhost;' >> /etc/nginx/conf.d/default.conf \
    && echo '    root /usr/share/nginx/html;' >> /etc/nginx/conf.d/default.conf \
    && echo '    index index.html;' >> /etc/nginx/conf.d/default.conf \
    && echo '' >> /etc/nginx/conf.d/default.conf \
    && echo '    # Proxy para auth-api' >> /etc/nginx/conf.d/default.conf \
    && echo '    location /login {' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_pass http://auth-api:8081/login;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header Host $host;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header X-Real-IP $remote_addr;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;' >> /etc/nginx/conf.d/default.conf \
    && echo '    }' >> /etc/nginx/conf.d/default.conf \
    && echo '' >> /etc/nginx/conf.d/default.conf \
    && echo '    # Proxy para users-api' >> /etc/nginx/conf.d/default.conf \
    && echo '    location /users {' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_pass http://users-api:8083/users;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header Host $host;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header X-Real-IP $remote_addr;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;' >> /etc/nginx/conf.d/default.conf \
    && echo '    }' >> /etc/nginx/conf.d/default.conf \
    && echo '' >> /etc/nginx/conf.d/default.conf \
    && echo '    # Proxy para todos-api' >> /etc/nginx/conf.d/default.conf \
    && echo '    location /todos {' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_pass http://todos-api:8082/todos;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header Host $host;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header X-Real-IP $remote_addr;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;' >> /etc/nginx/conf.d/default.conf \
    && echo '    }' >> /etc/nginx/conf.d/default.conf \
    && echo '' >> /etc/nginx/conf.d/default.conf \
    && echo '    # Proxy para zipkin tracing' >> /etc/nginx/conf.d/default.conf \
    && echo '    location /zipkin {' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_pass http://zipkin:9411/api/v2/spans;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header Host $host;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header X-Real-IP $remote_addr;' >> /etc/nginx/conf.d/default.conf \
    && echo '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;' >> /etc/nginx/conf.d/default.conf \
    && echo '    }' >> /etc/nginx/conf.d/default.conf \
    && echo '' >> /etc/nginx/conf.d/default.conf \
    && echo '    # Servir archivos estáticos y SPA routing' >> /etc/nginx/conf.d/default.conf \
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

