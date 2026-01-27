# 1) Build stage
FROM node:20-alpine AS build
WORKDIR /app

# package manager: npm 기준
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# 2) Run stage: nginx로 정적 파일 서빙
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]