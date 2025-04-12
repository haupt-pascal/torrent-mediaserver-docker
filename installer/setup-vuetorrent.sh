#!/bin/bash
# Setup-Script for VueTorrent as an alternative WebUI for qBittorrent/qBittorrent-nox

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== qBittorrent VueTorrent Setup ===${NC}"
echo "This script will set up VueTorrent as the WebUI for qBittorrent."

# Create directory for VueTorrent
mkdir -p ./vuetorrent

# Download the latest release of VueTorrent
echo -e "\n${YELLOW}Downloading latest VueTorrent release...${NC}"
LATEST_RELEASE=$(curl -s https://api.github.com/repos/VueTorrent/VueTorrent/releases/latest | grep "tag_name" | cut -d'"' -f4)
echo "Latest release: $LATEST_RELEASE"

# Download and extract VueTorrent
curl -L https://github.com/VueTorrent/VueTorrent/releases/latest/download/vuetorrent.zip -o ./vuetorrent/vuetorrent.zip
unzip -o ./vuetorrent/vuetorrent.zip -d ./vuetorrent
rm ./vuetorrent/vuetorrent.zip

echo -e "${GREEN}VueTorrent has been downloaded and extracted to ./vuetorrent${NC}"

# Create a script to setup qBittorrent to use VueTorrent
cat > ./vuetorrent/setup-qbittorrent-config.sh << 'EOF'
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
    sed -i '/\[Preferences\]/,/\[.*\]/ s|^WebUI\\AlternativeUIEnabled=.*|WebUI\\AlternativeUIEnabled=true|' "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"
    sed -i '/\[Preferences\]/,/\[.*\]/ s|^WebUI\\RootFolder=.*|WebUI\\RootFolder=/vuetorrent|' "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"

    # If the WebUI section doesn't exist, add it
    if ! grep -q "\[WebUI\]" "$CONFIG_DIR/qBittorrent/config/qBittorrent.conf"; then
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

chmod +x ./vuetorrent/setup-qbittorrent-config.sh

# Create entrypoint scripts for both qBittorrent and qBittorrent-nox
cat > ./vuetorrent/entrypoint.sh << 'EOF'
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

chmod +x ./vuetorrent/entrypoint.sh

echo -e "\n${YELLOW}Checking docker-compose.yml file...${NC}"

# Check if docker-compose.yml exists
if [ -f "docker-compose.yml" ]; then
    # Ask which version of qBittorrent to use
    echo -e "\n${GREEN}Which qBittorrent version would you like to use?${NC}"
    echo "1) Standard qBittorrent (LinuxServer image with GUI)"
    echo "2) qBittorrent-nox (Official headless image, generally faster)"
    read -p "Enter your choice (1 or 2): " qb_choice

    case $qb_choice in
        1)
            # Enable standard qBittorrent, disable nox
            sed -i 's/^#\s*qbittorrent:/  qbittorrent:/' docker-compose.yml
            sed -i 's/^#\s*\(.*\) # Uncomment the line below when using VueTorrent/  entrypoint: \/vuetorrent\/entrypoint.sh/' docker-compose.yml
            sed -i '/^  qbittorrent-nox:/,/^  [a-z]/{s/^  /  #/}' docker-compose.yml
            echo -e "${GREEN}Configured for standard qBittorrent${NC}"
            ;;
        2)
            # Enable qBittorrent-nox, disable standard
            sed -i '/^  qbittorrent:/,/^  [a-z]/{s/^  /  #/}' docker-compose.yml
            sed -i 's/^#\s*qbittorrent-nox:/  qbittorrent-nox:/' docker-compose.yml
            sed -i 's/^#\s*  entrypoint: \/vuetorrent\/entrypoint.sh/  entrypoint: \/vuetorrent\/entrypoint.sh/' docker-compose.yml
            echo -e "${GREEN}Configured for qBittorrent-nox${NC}"
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Please edit docker-compose.yml manually.${NC}"
            ;;
    esac
else
    echo -e "${YELLOW}docker-compose.yml not found. Skipping automatic configuration.${NC}"
    echo "Please manually edit your docker-compose.yml to use the entrypoint script."
fi

echo -e "\n${GREEN}Setup completed!${NC}"
echo "Run 'docker-compose up -d' to start your containers."
echo "VueTorrent will be available at http://localhost:8080 after qBittorrent starts."
echo "Default login credentials: admin / adminadmin"
