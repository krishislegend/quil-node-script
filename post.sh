#!/bin/bash

# Ensure the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Wait a bit for the system to stabilize after reboot
sleep 60

# Source the environment variables permanently
echo 'export GOROOT=/usr/local/go' >> /etc/profile
echo 'export GOPATH=$HOME/go' >> /etc/profile
echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> /etc/profile
source /etc/profile

# Clone the repository and perform setup
git clone https://github.com/QuilibriumNetwork/ceremonyclient.git /root/ceremonyclient
cd /root/ceremonyclient/node

# Run go run in the background
if [ -f "/root/voucher.hex" ]; then
    GOEXPERIMENT=arenas go run ./... -import-priv-key "$(cat /root/voucher.hex)" &
else
    GOEXPERIMENT=arenas go run ./... &
fi

# Capture the PID of the last background process
PID=$!

# Allow the process to initialize for 5 minutes
sleep 300

# Check if the process is still running and kill it
if kill -0 $PID 2>/dev/null; then
    echo "Killing long-running go process."
    kill $PID
fi


# Kill node process after initialization
echo "Stopping node process..."
pkill -f "go/bin/node"

# Configure .config/config.yml for gRPC and stats
echo "Configuring gRPC and stats in config.yml..."
sed -i 's/listenGrpcMultiaddr: ""/listenGrpcMultiaddr: "\/ip4\/127.0.0.1\/tcp\/8337"/' .config/config.yml
sed -i '/statsMultiaddr/d' .config/config.yml  # This removes existing lines containing 'statsMultiaddr'
sed -i '/engine:/a \  statsMultiaddr: "/dns/stats.quilibrium.com/tcp/443"' .config/config.yml

# Build the node application
echo "Building node application..."
GOEXPERIMENT=arenas go install ./...
echo "Node binary build completed."

# Verify that the node binary is built
if [ -f "/root/go/bin/node" ]; then
    echo "Node binary is present."
else
    echo "Error: Node binary is not present."
    exit 1
fi

# Setup the node service
echo "Creating system service for the node..."
cat > /lib/systemd/system/ceremonyclient.service <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=/root/ceremonyclient/node
Environment=GOEXPERIMENT=arenas
ExecStart=/root/go/bin/node ./...

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize new service, start and enable on boot
systemctl daemon-reload
systemctl enable ceremonyclient
systemctl start ceremonyclient

# Setup Firewall
ufw allow 22
ufw allow 8336
ufw allow 443
ufw --force enable

# Clear the cron job so it doesn't run again on subsequent reboots
#(crontab -l | grep -v '@reboot') | crontab -

echo "Node setup complete. The node has started successfully."

# Show node service status
systemctl status ceremonyclient --no-pager
