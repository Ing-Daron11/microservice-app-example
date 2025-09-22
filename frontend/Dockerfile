#============================================================
#Stage 1: Build (con Node antiguo para compatibilidad)
#============================================================
FROM node:8.17.0 AS builder

#Set working directory
WORKDIR /app

#Copiar package.json e instalar dependencias
COPY package.json ./

#Instalar dependencias
RUN npm install

#Copiar el resto del código fuente
COPY . .

#Build del frontend
RUN npm run build

#============================================================
#Stage 2: Producción (servir con Nginx)
#============================================================
FROM nginx:alpine AS production

#Directorio de Nginx
WORKDIR /usr/share/nginx/html

#Limpiar contenido por defecto
RUN rm -rf ./*

#Copiar archivos generados del builder
COPY --from=builder /app/dist . 

# Copiar configuración personalizada de nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Instalar wget para healthcheck
RUN apk add --no-cache wget

# Exponer puerto
EXPOSE 80

# Healthcheck simple
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Comando por defecto (ejecutar como root para evitar problemas de permisos)
CMD ["nginx", "-g", "daemon off;"]

