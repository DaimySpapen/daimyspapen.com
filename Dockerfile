FROM node:24.18.0-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 8000

CMD ["node", "server.js"]