#!/bin/bash

# Variables
REPO="mhellnerdev/api_exporter"  # Your GitHub username and repository
ASSET_NAME="api_exporter"         # Name of your binary
INSTALL_DIR="/etc/api_exporter"
CONFIG_FILE="$INSTALL_DIR/api_config.yml"
SERVICE_FILE="/etc/systemd/system/api_exporter.service"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')  # Get the OS name
ARCH=$(uname -m)                   # Get the architecture
USER_NAME="api_exporter"           # User to run the service

# Create a user for the API Exporter if it doesn't exist
if ! id "$USER_NAME" &>/dev/null; then
    echo "Creating user $USER_NAME..."
    sudo useradd -r -s /bin/false "$USER_NAME"
fi

# Determine the appropriate asset name based on OS and architecture
if [[ "$OS" == "linux" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        ASSET_NAME="${ASSET_NAME}_linux_amd64"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
elif [[ "$OS" == "darwin" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        ASSET_NAME="${ASSET_NAME}_darwin_amd64"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Fetch the latest release download URL
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r ".assets[] | select(.name | contains(\"$ASSET_NAME\")) | .browser_download_url")

# Check if the URL was found
if [ -z "$LATEST_RELEASE" ]; then
    echo "Could not find the latest release for $ASSET_NAME"
    exit 1
fi

echo "Downloading $LATEST_RELEASE..."
curl -L -o "$ASSET_NAME" "$LATEST_RELEASE"

# Make the binary executable
chmod +x "$ASSET_NAME"

# Create the installation directory
sudo mkdir -p "$INSTALL_DIR"

# Move the binary to the installation directory
sudo mv "$ASSET_NAME" "$INSTALL_DIR/$ASSET_NAME"

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
ExecStart=$INSTALL_DIR/$ASSET_NAME --web.listen-address=0.0.0.0:9105 --config.api-config=$CONFIG_FILE
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
