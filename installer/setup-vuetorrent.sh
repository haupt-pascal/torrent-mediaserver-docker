#!/bin/bash
# Setup-Script for VueTorrent as an alternative WebUI for qBittorrent/qBittorrent-nox
# This script is designed to be located in the installer/ directory

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the parent directory (project root)
PROJECT_ROOT="$(dirname "$(dirname "$(readlink -f "$0")")")"
VUETORRENT_DIR="${PROJECT_ROOT}/vuetorrent"

echo -e "${GREEN}=== qBittorrent VueTorrent Setup ===${NC}"
echo "This script will set up VueTorrent as the WebUI for qBittorrent."
echo -e "Project root: ${YELLOW}${PROJECT_ROOT}${NC}"
echo -e "VueTorrent dir: ${YELLOW}${VUETORRENT_DIR}${NC}"

# Create directory for VueTorrent
mkdir -p "${VUETORRENT_DIR}"

# Download the latest release of VueTorrent
echo -e "\n${YELLOW}Downloading latest VueTorrent release...${NC}"
LATEST_RELEASE=$(curl -s https://api.github.com/repos/VueTorrent/VueTorrent/releases/latest | grep "tag_name" | cut -d'"' -f4)
echo "Latest release: $LATEST_RELEASE"

# Download and extract VueTorrent
curl -L https://github.com/VueTorrent/VueTorrent/releases/latest/download/vuetorrent.zip -o "${VUETORRENT_DIR}/vuetorrent.zip"
unzip -o "${VUETORRENT_DIR}/vuetorrent.zip" -d "${VUETORRENT_DIR}"
rm "${VUETORRENT_DIR}/vuetorrent.zip"

echo -e "${GREEN}VueTorrent has been downloaded and extracted to ${VUETORRENT_DIR}${NC}"

# Create a script to setup qBittorrent to use VueTorrent
cat > "${VUETORRENT_DIR}/setup-qbittorrent-config.sh" << 'EOF'
#!/bin/bash
# This script will run inside the container to configure qBittorrent

# Default qBittorrent config directory inside the container
CONFIG_DIR="/config"
WEBUI_DIR="/vuetorrent"

# Check if we're running in qbittorrent or qbittorrent-nox
IS_NOX=false
if command -v qbittorrent-nox &> /dev/null; then
    IS_NOX=true
    echo "Detected qBittorrent-nox"
else
    echo "Detected standard qBittorrent"
fi

# Wait for qBittorrent to create the initial config
echo "Waiting for qBittorrent configuration to initialize..."
sleep 10

# Check if config file exists
if [ ! -f "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf" ]; then
    echo "qBittorrent config file not found! Starting qBittorrent to generate default config..."
    if [ "$IS_NOX" = true ]; then
        qbittorrent-nox --webui-port=8080 &
    else
        # For standard qBittorrent, the command might vary depending on the image
        # This is a fallback that may work in LinuxServer images
        /usr/bin/qbittorrent --webui-port=8080 &
    fi
    sleep 15
    pkill -f qbittorrent
    sleep 5
fi

# Configure qBittorrent to use VueTorrent as alternative WebUI
if [ -f "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf" ]; then
    echo "Configuring qBittorrent to use VueTorrent..."

    # Create qBittorrent config if it doesn't exist
    mkdir -p "$CONFIG_DIR/qBittorrent/config"

    # Set alternative WebUI path
    if grep -q "\[WebUI\]" "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"; then
        sed -i '/\[WebUI\]/,/\[.*\]/ s|^AlternativeUIEnabled=.*|AlternativeUIEnabled=true|' "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"
        sed -i '/\[WebUI\]/,/\[.*\]/ s|^RootFolder=.*|RootFolder=/vuetorrent|' "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"
    else
        # If WebUI section doesn't exist, add it
        echo "" >> "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"
        echo "[WebUI]" >> "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"
        echo "AlternativeUIEnabled=true" >> "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"
        echo "RootFolder=/vuetorrent" >> "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"
    fi

    # Create symlink for backward compatibility (some Docker setups might need this)
    if [ ! -L "$CONFIG_DIR/qBittorrent/config/vuetorrent" ]; then
        ln -sf "$WEBUI_DIR" "$CONFIG_DIR/qBittorrent/config/vuetorrent"
    fi

    echo "qBittorrent configuration completed!"
else
    echo "qBittorrent config file not found after waiting. Please check your setup."
    exit 1
fi
EOF

chmod +x "${VUETORRENT_DIR}/setup-qbittorrent-config.sh"

# Create entrypoint scripts for both qBittorrent and qBittorrent-nox
cat > "${VUETORRENT_DIR}/entrypoint.sh" << 'EOF'
#!/bin/bash

# Run the configuration script
/vuetorrent/setup-qbittorrent-config.sh &

# Detect which qBittorrent version we're using
if command -v qbittorrent-nox &> /dev/null; then
    # Start qBittorrent-nox with the configured WebUI port
    exec qbittorrent-nox --webui-port=8080
else
    # For standard qBittorrent (usually from LinuxServer), we need to let the
    # original entrypoint handle it, so we exit and let the container continue
    # its normal startup process
    exit 0
fi
EOF

chmod +x "${VUETORRENT_DIR}/entrypoint.sh"

echo -e "\n${YELLOW}Checking docker-compose files...${NC}"

# Check different docker-compose files
COMPOSE_FILES=("${PROJECT_ROOT}/docker-compose.yaml" "${PROJECT_ROOT}/docker-compose.yml" "${PROJECT_ROOT}/docker-compose.all.yaml")

for COMPOSE_FILE in "${COMPOSE_FILES[@]}"; do
    if [ -f "${COMPOSE_FILE}" ]; then
        echo -e "Found compose file: ${YELLOW}${COMPOSE_FILE}${NC}"

        # Check if the file already has the entrypoint configuration for qbittorrent-nox
        if grep -q "qbittorrent-nox" "${COMPOSE_FILE}" && ! grep -q "entrypoint.*vuetorrent/entrypoint.sh" "${COMPOSE_FILE}"; then
            echo -e "${YELLOW}Adding entrypoint configuration to ${COMPOSE_FILE}${NC}"

            # Use sed to add the entrypoint line after the hostname line for qbittorrent-nox
            sed -i '/hostname: qbittorrent/a\    entrypoint: /vuetorrent/entrypoint.sh' "${COMPOSE_FILE}"
        fi
    fi
done

echo -e "\n${GREEN}Setup completed!${NC}"
echo "Run 'docker-compose up -d' to start your containers."
echo "VueTorrent will be available at http://localhost:8080 after qBittorrent starts."
echo "Default login credentials: admin / adminadmin"
