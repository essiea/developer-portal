# --- Build stage ---
FROM node:20-alpine AS build
WORKDIR /app

# Copy both package.json and package-lock.json (if present)
COPY package*.json ./

# Install deps (including recharts)
RUN npm install

# Copy app source
COPY . .

# Build-time envs
ARG VITE_COGNITO_DOMAIN
ARG VITE_COGNITO_CLIENT_ID
ARG VITE_API_BASE=/api
ENV VITE_COGNITO_DOMAIN=$VITE_COGNITO_DOMAIN
ENV VITE_COGNITO_CLIENT_ID=$VITE_COGNITO_CLIENT_ID
ENV VITE_API_BASE=$VITE_API_BASE

# Run vite build
RUN npm run build

# --- Runtime stage ---
FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx","-g","daemon off;"]

