#!/bin/bash
set -e

# Variables
ASSET_NAME="api_exporter_linux_amd64.tar.gz"  # Name of the tar.gz file
INSTALL_DIR="/etc/api_exporter"
CONFIG_FILE="$INSTALL_DIR/api_config.yml"
SERVICE_FILE="/etc/systemd/system/api_exporter.service"
USER_NAME="api_exporter"           # User to run the service

# Direct download URL for the asset
LATEST_RELEASE="https://github.com/mhellnerdev/api_exporter/releases/download/latest/$ASSET_NAME"

# Create a user for the API Exporter if it doesn't exist
if ! id "$USER_NAME" &>/dev/null; then
    echo "Creating user $USER_NAME..."
    sudo useradd -r -s /bin/false "$USER_NAME"
fi

# Check if the URL is reachable
if ! curl --output /dev/null --silent --head --fail "$LATEST_RELEASE"; then
    echo "Could not find the latest release for $ASSET_NAME at $LATEST_RELEASE"
    exit 1
fi

echo "Downloading $LATEST_RELEASE..."
curl -L -o "$ASSET_NAME" "$LATEST_RELEASE"

# Create the installation directory
sudo mkdir -p "$INSTALL_DIR"

# Unpack the tar.gz file
tar -xzvf "$ASSET_NAME" -C "$INSTALL_DIR"

# Move the binary to the installation directory
sudo mv "$INSTALL_DIR/api_exporter_linux_amd64/api_exporter" "$INSTALL_DIR/"

# Create a base configuration file
cat <<EOL | sudo tee "$CONFIG_FILE"
api_keys:
  "https://api.example.com":
    key: "your_api_key"
    header: "x-api-key"
  "https://another.api.com":
    key: "another_api_key"
    header: "x-api-key"
EOL

# Change ownership of the installation directory and config file
sudo chown -R "$USER_NAME":"$USER_NAME" "$INSTALL_DIR"

# Create the systemd service file
cat <<EOL | sudo tee "$SERVICE_FILE"
[Unit]
Description=API Exporter
After=network.target

[Service]
ExecStart=$INSTALL_DIR/api_exporter --config.api-config=$CONFIG_FILE
Restart=always
User=$USER_NAME
Group=$USER_NAME

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable api_exporter
sudo systemctl start api_exporter

echo "API Exporter installed and started successfully!"