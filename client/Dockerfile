# Stage 1: Build React app
FROM node:18-alpine AS build

WORKDIR /app

ARG REACT_APP_SERVER_URL
ENV REACT_APP_SERVER_URL=$REACT_APP_SERVER_URL

COPY package.json package-lock.json ./
RUN npm ci

COPY . ./

RUN npm run build

# Stage 2: Serve with nginx (same as before)
FROM nginx:stable-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
