# Stage 1: Build React app
FROM node:18-alpine AS build

WORKDIR /app

ARG REACT_APP_SERVER_URL
ENV REACT_APP_SERVER_URL=$REACT_APP_SERVER_URL

COPY package.json package-lock.json ./
RUN npm ci

COPY . ./

RUN npm run build

# Stage 2: Serve with nginx for SPA
FROM nginx:stable-alpine

# Remove default nginx config
RUN rm -rf /usr/share/nginx/html/*
RUN rm /etc/nginx/conf.d/default.conf

# Copy React build
COPY --from=build /app/build /usr/share/nginx/html

# Add SPA-friendly nginx configuration
COPY nginx-spa.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
