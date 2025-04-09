FROM node:20-alpine AS builder

RUN apk --no-cache add curl

# Створюємо директорію і налаштовуємо права
RUN mkdir -p /app && chown node:node /app
WORKDIR /app

USER node

# Копіюємо лише необхідні файли для фронтенду
COPY --chown=node:node package.json package-lock.json ./
COPY --chown=node:node client/ ./client/
COPY --chown=node:node next.config.js ./
COPY --chown=node:node public/ ./public/

# Встановлюємо залежності та будуємо фронтенд
RUN \
    npm config set fetch-retry-maxtimeout 600000 ; \
    npm config set fetch-retries 5 ; \
    npm config set fetch-retry-mintimeout 15000 ; \
    npm install --no-audit ; \
    NODE_OPTIONS="--max-old-space-size=2048" npm run frontend ; \
    npm prune --production ; \
    npm cache clean --force

# Фінальний образ
FROM node:20-alpine

WORKDIR /app

# Копіюємо зібраний фронтенд
COPY --from=builder --chown=node:node /app/package.json /app/package-lock.json ./
COPY --from=builder --chown=node:node /app/.next ./.next
COPY --from=builder --chown=node:node /app/public ./public
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/next.config.js ./

# Копіюємо librechat.yaml для конфігурації
COPY --chown=node:node librechat.yaml ./

EXPOSE 3080

ENV HOST=0.0.0.0
CMD ["npm", "run", "start"]