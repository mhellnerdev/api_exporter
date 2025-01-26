#!/bin/sh
set -e

# Variables
REPO="mhellnerdev/api_exporter"  # Your GitHub username and repository
ASSET_NAME="api_exporter_linux_amd64.tar.gz"  # Name of the tar.gz file
INSTALL_DIR="/etc/api_exporter"
CONFIG_FILE="$INSTALL_DIR/api_config.yml"
SERVICE_FILE="/etc/systemd/system/api_exporter.service"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')  # Get the OS name
ARCH=$(uname -m)                   # Get the architecture
USER_NAME="api_exporter"           # User to run the service

# Create a user for the API Exporter if it doesn't exist
if ! id "$USER_NAME" >/dev/null 2>&1; then
    echo "Creating user $USER_NAME..."
    sudo useradd -r -s /bin/false "$USER_NAME"
fi

# Determine the appropriate asset name based on OS and architecture
if [ "$OS" = "linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        ASSET_NAME="api_exporter_linux_amd64.tar.gz"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
elif [ "$OS" = "darwin" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        ASSET_NAME="api_exporter_darwin_amd64.tar.gz"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Fetch the latest release download URL
RESPONSE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")

# Check if the response is empty
if [ -z "$RESPONSE" ]; then
    echo "Failed to fetch the latest release. Please check the repository and your network connection."
    exit 1
fi

# Extract the download URL using jq
LATEST_RELEASE=$(echo "$RESPONSE" | jq -r ".assets[] | select(.name | contains(\"$ASSET_NAME\")) | .browser_download_url")

# Check if the URL was found
if [ -z "$LATEST_RELEASE" ]; then
    echo "Could not find the latest release for $ASSET_NAME"
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