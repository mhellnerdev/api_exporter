#!/bin/bash
set -e

# Variables
INSTALL_DIR="/etc/api_exporter"
CONFIG_FILE="$INSTALL_DIR/api_exporter.yml"
SERVICE_FILE="/etc/systemd/system/api_exporter.service"
USER_NAME="api_exporter"           # User to run the service

# Stop and disable the service
if systemctl is-active --quiet api_exporter; then
    echo "Stopping API Exporter service..."
    sudo systemctl stop api_exporter
fi

if systemctl is-enabled --quiet api_exporter; then
    echo "Disabling API Exporter service..."
    sudo systemctl disable api_exporter
fi

# Remove the systemd service file
if [ -f "$SERVICE_FILE" ]; then
    echo "Removing systemd service file..."
    sudo rm "$SERVICE_FILE"
fi

# Reload systemd to reflect changes
sudo systemctl daemon-reload

# Remove the installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing installation directory..."
    sudo rm -r "$INSTALL_DIR"
fi

# Remove the api_exporter user
if id "$USER_NAME" &>/dev/null; then
    echo "Removing user $USER_NAME..."
    sudo userdel "$USER_NAME"
fi

echo "API Exporter uninstalled successfully!" 