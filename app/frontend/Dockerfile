# Build stage
FROM node:18 AS builder

WORKDIR /app

COPY ./client ./client

WORKDIR /app/client

# Встановлення залежностей
RUN npm install

# Аргумент для білду
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# Білд Next.js фронтенду
RUN npm run build

# Production stage
FROM node:18-alpine AS runner

WORKDIR /app

COPY --from=builder /app/client/.next .next
COPY --from=builder /app/client/public ./public
COPY --from=builder /app/client/package.json ./package.json
COPY --from=builder /app/client/node_modules ./node_modules

EXPOSE 3000

CMD ["npm", "start"]