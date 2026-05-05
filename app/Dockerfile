# Flutter Web Render deployment
# Multi-stage: build Flutter web, serve via nginx
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_VERSION=3.24.0
ENV FLUTTER_DIR=/opt/flutter

RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | \
    tar xJ -C /opt

ENV PATH="${FLUTTER_DIR}/bin:${PATH}"

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build Flutter web to docs/
RUN flutter build web --base-href=/ --output-dir=docs

# Production stage: serve with nginx
FROM nginx:1.25-alpine

# Remove default nginx site
RUN rm -rf /usr/share/nginx/html/*

# Copy Flutter build output
COPY --from=builder /app/docs /usr/share/nginx/html

# Custom nginx config for Flutter web (SPA routing)
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location /assets/ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
}' > /etc/nginx/http.d/flutter.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
