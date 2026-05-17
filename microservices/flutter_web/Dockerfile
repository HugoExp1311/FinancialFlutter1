# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /workspace

# Copy core_domain package
COPY packages/core_domain/ ./packages/core_domain/

# Copy Flutter app
COPY app/ ./app/

# Build from app directory
WORKDIR /workspace/app
RUN flutter pub get
# Note: Isar doesn't fully support web due to JS integer limitations
# This build will fail if Isar models are used. Consider using conditional imports.
RUN flutter build web --release --web-renderer canvaskit --no-tree-shake-icons

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built web app
COPY --from=build /workspace/app/build/web /usr/share/nginx/html

# Copy nginx config
COPY microservices/flutter_web/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
