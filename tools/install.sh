#!/bin/sh
set -e

# Constants
GITHUB_URL="https://github.com/mhellnerdev/api_exporter/releases/download/latest/api_exporter_linux_amd64.tar.gz"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/api_exporter.service"

# --- helper functions for logs ---
info() {
    echo '[INFO] ' "$@"
}
fatal() {
    echo '[ERROR] ' "$@" >&2
    exit 1
}

# --- download the binary ---
download_binary() {
    info "Downloading API Exporter from $GITHUB_URL"
    curl -L -o "$INSTALL_DIR/api_exporter" "$GITHUB_URL"
}

# --- install the binary ---
install_binary() {
    chmod +x "$INSTALL_DIR/api_exporter"
    info "Installed API Exporter to $INSTALL_DIR/api_exporter"
}

# --- create systemd service file ---
create_service_file() {
    info "Creating systemd service file at $SERVICE_FILE"
    cat << EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=API Exporter
After=network.target

[Service]
ExecStart=$INSTALL_DIR/api_exporter --config.api-config=/etc/api_exporter/api_config.yml
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF
}

# --- enable and start the service ---
enable_and_start_service() {
    info "Enabling and starting API Exporter service"
    sudo systemctl daemon-reload
    sudo systemctl enable api_exporter
    sudo systemctl start api_exporter
}

# --- main installation process ---
{
    download_binary
    install_binary
    create_service_file
    enable_and_start_service
} || {
    fatal "Installation failed"
}

info "API Exporter installed successfully!"