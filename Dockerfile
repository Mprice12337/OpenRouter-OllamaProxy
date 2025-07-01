# Stage 1: Build the Go application
FROM golang:latest AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -o ollama-proxy

# Stage 2: Create the final lightweight image
FROM alpine:latest
LABEL author="Mark Nefedov"
LABEL org.opencontainers.image.source="https://github.com/marknefedov/ollama-openrouter-proxy"

# Copy SSL certificates from the builder stage for HTTPS connections
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Set environment variables for permissions
ENV UMASK=000
ENV PUID=99
ENV PGID=100

RUN apk add --no-cache su-exec

# Create app directory for the binary and default config
RUN mkdir -p /app /config

COPY --from=builder /app/ollama-proxy /app/ollama-proxy
COPY models-filter /app/models-filter.default
COPY entrypoint.sh /app/entrypoint.sh

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

# Set working directory to the config directory
WORKDIR /config

# Expose the application port
EXPOSE 11434

# Define a volume for the configuration
VOLUME /config

# Run entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]