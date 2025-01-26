#!/bin/bash
set -e

# Variables
INSTALL_DIR="/etc/api_exporter"
CONFIG_FILE="$INSTALL_DIR/api_config.yml"
SERVICE_FILE="/etc/systemd/system/api_exporter.service"
USER_NAME="api_exporter"           # User to run the service
RELEASE_TAR="api_exporter_linux_amd64.tar.gz"  # Name of the release tar.gz file
RELEASE_DIR="./release"            # Path to the release folder
BINARY_NAME="api_exporter"        # Name of the binary
TMP_DIR="/tmp/api_exporter_install"  # Temporary directory for unpacking

# Create a user for the API Exporter if it doesn't exist
if ! id "$USER_NAME" &>/dev/null; then
    echo "Creating user $USER_NAME..."
    sudo useradd -r -s /bin/false "$USER_NAME"
fi

# Check if the release tar.gz file exists
if [ ! -f "$RELEASE_DIR/$RELEASE_TAR" ]; then
    echo "Error: Release file '$RELEASE_TAR' not found in the '$RELEASE_DIR' folder."
    exit 1
fi

# Create the installation directory
sudo mkdir -p "$INSTALL_DIR"

# Create a temporary directory for unpacking
mkdir -p "$TMP_DIR"

# Unpack the tar.gz file into the temporary directory
echo "Unpacking $RELEASE_TAR to $TMP_DIR..."
sudo tar -xzvf "$RELEASE_DIR/$RELEASE_TAR" -C "$TMP_DIR"

# Move the binary to the installation directory
if [ -f "$TMP_DIR/api_exporter_linux_amd64/$BINARY_NAME" ]; then
    echo "Moving binary to $INSTALL_DIR..."
    sudo mv "$TMP_DIR/api_exporter_linux_amd64/$BINARY_NAME" "$INSTALL_DIR/"
else
    echo "Error: Binary '$BINARY_NAME' not found in the unpacked release."
    exit 1
fi

# Clean up the temporary directory
echo "Cleaning up temporary files..."
rm -r "$TMP_DIR"

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
ExecStart=$INSTALL_DIR/$BINARY_NAME --config.api-config=$CONFIG_FILE
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