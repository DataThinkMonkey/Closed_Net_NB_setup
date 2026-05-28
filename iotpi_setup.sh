#!/bin/bash
# iotpi_setup.sh - Run this on IoTpi while connected to PCpi

set -e

echo "========================================================="
echo " Offline Jupyter Setup Initialization (Trixie to Trixie)"
echo "========================================================="
read -p "Enter the IP address of PCpi (e.g., 169.254.x.x): " PCPI_IP

if [ -z "$PCPI_IP" ]; then
    echo "ERROR: IP address cannot be empty."
    exit 1
fi

PCPI_HOST="${PCPI_IP}:8080"
USER_HOME="/home/$USER"
ENV_DIR="$USER_HOME/jupyter-env"
NOTEBOOK_DIR="$USER_HOME/Jupyter_Notebooks"

echo "Using provisioning server at: http://$PCPI_HOST"
echo "---------------------------------------------------------"

mkdir -p "$NOTEBOOK_DIR"
rm -rf /tmp/apt_staging && mkdir -p /tmp/apt_staging

# 1. Fetch lean system packages from PCpi
echo "--> Fetching clean Debian dependency pool from PCpi..."
cd /tmp/apt_staging
wget -r -np -nH -R "index.html*" --execute robots=off http://$PCPI_HOST/apt/

APT_LOCAL="/tmp/apt_staging/apt"

# 2. Safely register and handle lean offline installation
echo "--> Registering offline packages..."
if ls "$APT_LOCAL"/*.deb >/dev/null 2>&1; then
    # Unpack and target ONLY our specified packages to keep it clean
    sudo dpkg -i "$APT_LOCAL"/media-types*.deb 2>/dev/null || true
    sudo dpkg -i "$APT_LOCAL"/python3-pip*.deb 2>/dev/null || true
    sudo dpkg -i "$APT_LOCAL"/python3-venv*.deb 2>/dev/null || true
    sudo dpkg -i "$APT_LOCAL"/python3-dev*.deb 2>/dev/null || true
else
    echo "ERROR: No .deb files found in $APT_LOCAL."
    exit 1
fi

echo "--> Finalizing core package tracking states..."
# Cleanly configure specifically our lean components, skipping old unconfigured system remnants
sudo dpkg --configure python3-pip python3-venv media-types 2>/dev/null || true

# 3. Setup Python Virtual Environment
echo "--> Creating Python Virtual Environment..."
python3 -m venv "$ENV_DIR"
source "$ENV_DIR/bin/activate"

# 4. Fetch and install Jupyter via local wheelhouse
echo "--> Fetching Python wheels..."
rm -rf /tmp/pip_staging && mkdir -p /tmp/pip_staging
cd /tmp/pip_staging
wget -r -np -nH -R "index.html*" --execute robots=off http://$PCPI_HOST/pip/

PIP_LOCAL="/tmp/pip_staging/pip"

echo "--> Installing Jupyter Notebook offline..."
pip install --no-index --find-links="$PIP_LOCAL" jupyter notebook

# 5. Fetch and extract Custom Notebooks
echo "--> Deploying custom notebooks to workspace..."
cd "$NOTEBOOK_DIR"
wget http://$PCPI_HOST/notebooks.tar.gz
tar -xzf notebooks.tar.gz
rm notebooks.tar.gz
chown -R $USER:$USER "$NOTEBOOK_DIR"

# 6. Generate and alter Jupyter Configuration
echo "--> Configuring Jupyter Server..."
mkdir -p "$USER_HOME/.jupyter"
CONFIG_FILE="$USER_HOME/.jupyter/jupyter_server_config.py"

cat << EOF > "$CONFIG_FILE"
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_origin = '*'
c.ServerApp.terminado_settings = {'shell_command': ['/bin/bash']}
c.ServerApp.tornado_settings = {
    'headers': {
        'Content-Security-Policy': "frame-ancestors 'self' *"
    }
}
EOF

# 7. Automate Password Creation (Hardcoded to "Passw0rd")
echo "--> Automating password security configuration..."
HASHED_PASSWORD=$("$ENV_DIR/bin/python3" -c "from jupyter_server.auth import passwd; print(passwd('Passw0rd'))")
echo "c.ServerApp.password = u'$HASHED_PASSWORD'" >> "$CONFIG_FILE"

# 8. Create the Systemd Background Service
echo "--> Creating Systemd Service..."
sudo tee /etc/systemd/system/jupyter.service > /dev/null << EOF
[Unit]
Description=Jupyter Notebook Server (Offline Link-Local)
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=$ENV_DIR/bin/jupyter notebook --config=$CONFIG_FILE
WorkingDirectory=$NOTEBOOK_DIR
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 9. Fire up the service
echo "--> Enabling and starting Jupyter service..."
sudo systemctl daemon-reload
sudo systemctl enable jupyter.service
sudo systemctl start jupyter.service

# 10. Dynamically locate the link-local IP of IoTpi
IOTPI_IP=$(ip -4 addr show | grep -oP '169\.254\.\d{1,3}\.\d{1,3}' | head -n 1)

if [ -z "$IOTPI_IP" ]; then
    IOTPI_IP="IoTpi.local"
fi

echo "========================================================="
echo "SETUP COMPLETE WITH CUSTOM NOTEBOOKS!"
echo "Access the notebook server from PCpi at:"
echo "http://${IOTPI_IP}:8888"
echo "Password is set to: Passw0rd"
echo "========================================================="
