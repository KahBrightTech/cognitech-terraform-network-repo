FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install --no-audit --prefer-offline --progress=false || \
    (echo "Retrying..." && npm cache clean --force && npm install)

COPY . .

RUN npm run build

FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html

COPY nginx.conf /etc/nginx/templates/default.conf.template

EXPOSE 80

# Dockerfile - update the CMD line
CMD ["/bin/sh", "-c", "envsubst '${BACKEND_URL}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]