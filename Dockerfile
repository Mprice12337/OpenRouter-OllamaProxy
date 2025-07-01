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

# Create a non-root user for better security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Create app directory for the binary and default config
RUN mkdir -p /app
COPY --from=builder /app/ollama-proxy /app/ollama-proxy
COPY models-filter /app/models-filter.default
COPY entrypoint.sh /app/entrypoint.sh

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

# Create config directory which will be used as a volume mount point
# and set ownership to the non-root user
RUN mkdir -p /config && chown -R appuser:appgroup /config /app

# Switch to the non-root user
USER appuser

# Set working directory to the config directory.
# The Go app reads 'models-filter' from its working directory.
WORKDIR /config

# Expose the application port
EXPOSE 11434

# Define a volume for the configuration.
# This allows users to mount a host directory to persist the models-filter file.
VOLUME /config

# Set the entrypoint to the shell script
ENTRYPOINT ["/app/entrypoint.sh"]