#!/bin/sh
# This script ensures that a default models-filter file is available
# if a volume is mounted and empty.

set -e

CONFIG_FILE_PATH="/config/models-filter"
DEFAULT_CONFIG_FILE_PATH="/app/models-filter.default"

# Check if the models-filter file exists in the config volume.
# If not, copy the default one from a location inside the container.
if [ ! -f "$CONFIG_FILE_PATH" ]; then
    echo "No models-filter file found in /config. Copying default file."
    cp "$DEFAULT_CONFIG_FILE_PATH" "$CONFIG_FILE_PATH"
else
    echo "Using existing models-filter file from /config."
fi

# The WORKDIR is set to /config, so the proxy will find the models-filter file.
# Now, execute the main application, passing along any command-line arguments.
echo "Starting ollama-proxy..."
exec /app/ollama-proxy "$@"
