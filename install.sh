#!/bin/bash
set -e

# Welcome to the API Exporter installer!
# This script will set up everything you need to get the API Exporter running.

# Variables
INSTALL_DIR="/etc/api_exporter"  # Where the magic happens
CONFIG_FILE="$INSTALL_DIR/api_exporter.yml"  # Configuration file for API keys
SERVICE_FILE="/etc/systemd/system/api_exporter.service"  # Systemd service file
USER_NAME="api_exporter"  # The user who will run the service
RELEASE_TAR="api_exporter_linux_amd64.tar.gz"  # The release tar.gz file
RELEASE_DIR="./release"  # Where the release file lives
BINARY_NAME="api_exporter"  # The name of the binary
TMP_DIR="/tmp/api_exporter_install"  # Temporary directory for unpacking

# Step 1: Create a user for the API Exporter (if it doesn't exist)
if ! id "$USER_NAME" &>/dev/null; then
    echo "Creating user '$USER_NAME' to run the API Exporter..."
    sudo useradd -r -s /bin/false "$USER_NAME"
fi

# Step 2: Check if the release tar.gz file exists
if [ ! -f "$RELEASE_DIR/$RELEASE_TAR" ]; then
    echo "Error: Release file '$RELEASE_TAR' not found in the '$RELEASE_DIR' folder."
    echo "   Make sure you've placed the release file in the correct location!"
    exit 1
fi

# Step 3: Create the installation directory
echo "Creating installation directory at $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"

# Step 4: Create a temporary directory for unpacking
echo "Setting up a temporary workspace in $TMP_DIR..."
mkdir -p "$TMP_DIR"

# Step 5: Unpack the tar.gz file into the temporary directory
echo "Unpacking $RELEASE_TAR into $TMP_DIR..."
sudo tar -xzvf "$RELEASE_DIR/$RELEASE_TAR" -C "$TMP_DIR"

# Step 6: Move the binary to the installation directory
if [ -f "$TMP_DIR/api_exporter_linux_amd64/$BINARY_NAME" ]; then
    echo "Moving the binary to $INSTALL_DIR..."
    sudo mv "$TMP_DIR/api_exporter_linux_amd64/$BINARY_NAME" "$INSTALL_DIR/"
else
    echo "Error: Binary '$BINARY_NAME' not found in the unpacked release."
    echo "   Did the release file contain the correct files?"
    exit 1
fi

# Step 7: Clean up the temporary directory
echo "Cleaning up temporary files in $TMP_DIR..."
rm -r "$TMP_DIR"

# Step 8: Create a base configuration file
echo "Creating a default configuration file at $CONFIG_FILE..."
cat <<EOL | sudo tee "$CONFIG_FILE"
api_keys:
  "https://api1.example.com":
    key: "your_api_key"
    header: "x-api-key"
  "https://api2.example.com":
    key: "your_api_key"
    header: "Authorization: Bearer"
  "https://api3.example.com":
    key: "your_api_key"
    header: "X-Auth-Token"
EOL

# Step 9: Change ownership of the installation directory and config file
echo "Setting ownership of $INSTALL_DIR to $USER_NAME..."
sudo chown -R "$USER_NAME":"$USER_NAME" "$INSTALL_DIR"

# Step 10: Create the systemd service file
echo "Setting up the systemd service at $SERVICE_FILE..."
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

# Step 11: Reload systemd to recognize the new service
echo "Reloading systemd to pick up the new service..."
sudo systemctl daemon-reload

# Step 12: Enable and start the service
echo "Enabling and starting the API Exporter service..."
sudo systemctl enable api_exporter
sudo systemctl start api_exporter

# All done!
echo "API Exporter installed and started successfully!"
echo "You're all set to monitor your APIs. Happy exporting!"