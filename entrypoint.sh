#!/bin/sh
# This script ensures that a default models-filter file is available
# if a volume is mounted and empty.

set -e

CONFIG_FILE_PATH="/config/models-filter"
DEFAULT_CONFIG_FILE_PATH="/app/models-filter.default"

# Apply the UMASK
umask ${UMASK:-000}

# Ensure /config directory has correct ownership
chown -R ${PUID:-99}:${PGID:-100} /config /app

# Check if the models-filter file exists in the config volume.
# If not, copy the default one from a location inside the container.
if [ ! -f "$CONFIG_FILE_PATH" ]; then
    echo "No models-filter file found in /config. Copying default file."
    cp "$DEFAULT_CONFIG_FILE_PATH" "$CONFIG_FILE_PATH"
    # Ensure the copied file has correct ownership
    chown ${PUID:-99}:${PGID:-100} "$CONFIG_FILE_PATH"
else
    echo "Using existing models-filter file from /config."
fi

# The WORKDIR is set to /config, so the proxy will find the models-filter file.
# Now, execute the main application as the specified user
echo "Starting ollama-proxy..."
exec su-exec ${PUID:-99}:${PGID:-100} /app/ollama-proxy "$@"