# Build context: application/frontend
# Stage 1 - Node toolchain builds the static bundle. The bundle is architecture-independent, so it is
# built once on the build machine's native platform even when the image targets amd64 + arm64.
FROM --platform=$BUILDPLATFORM node:22-alpine AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm test && npm run build

# Stage 2 - unprivileged nginx serves it (runs as UID 101, listens on 8080)
FROM nginxinc/nginx-unprivileged:1.29-alpine
# The upstream image lags Alpine's security updates; pull in every fixed package, then drop root again.
USER root
RUN apk upgrade --no-cache
USER 101
ENV BACKEND_URL=http://backend:8000
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=build /src/dist /usr/share/nginx/html
EXPOSE 8080
