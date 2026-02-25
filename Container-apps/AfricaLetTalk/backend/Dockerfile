FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --production --no-audit --prefer-offline --progress=false || \
    (echo "Retrying npm install..." && npm cache clean --force && npm install --production)

COPY . .

RUN mkdir -p uploads

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "src/index.js"]
