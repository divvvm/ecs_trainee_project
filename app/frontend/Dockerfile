FROM node:18 AS builder

WORKDIR /app
    
COPY . .
    
RUN npm install
RUN npm run build
    
FROM node:18-alpine
    
WORKDIR /app
    
COPY --from=builder /app .
    
ENV NODE_ENV=production
ENV PORT=3080
    
ARG OPENAI_API_HOST
ENV OPENAI_API_HOST=${OPENAI_API_HOST}
    
EXPOSE 3080
    
CMD ["npm", "start"]