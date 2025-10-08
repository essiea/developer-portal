# --- Build stage ---
FROM node:20-alpine AS build

WORKDIR /app

# Copy only dependency manifests first (better layer caching)
COPY package.json package-lock.json* ./

# Install deps
RUN npm install --production=false

# Copy the rest of your app
COPY . .

# Build-time args for vite
ARG VITE_COGNITO_DOMAIN
ARG VITE_COGNITO_CLIENT_ID
ARG VITE_API_BASE=/api

# Pass them into vite build
ENV VITE_COGNITO_DOMAIN=$VITE_COGNITO_DOMAIN
ENV VITE_COGNITO_CLIENT_ID=$VITE_COGNITO_CLIENT_ID
ENV VITE_API_BASE=$VITE_API_BASE

# Run vite build
RUN npm run build

# --- Runtime stage ---
FROM nginx:stable-alpine

# Copy built frontend
COPY --from=build /app/dist /usr/share/nginx/html

# Custom nginx config (reverse proxy /api -> backend service)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

