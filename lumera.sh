#!/bin/bash

set -e

echo "========================================="
echo "       🚀 Installing Lumera Node         "
echo "========================================="

# Step 1: Update & install dependencies
echo "========================================="
echo "  Step 1: Update & install dependencies  "
echo "========================================="
echo "🔧 Updating packages and installing dependencies..."
sudo apt update
sudo apt-get install git curl build-essential make jq gcc snapd chrony lz4 tmux unzip bc -y

# Step 2: Install Go
echo "========================================="
echo "          Step 2: Install Go            "
echo "========================================="
echo "🔧 Installing Go 1.23.5..."
rm -rf $HOME/go
sudo rm -rf /usr/local/go
cd $HOME
curl -s https://dl.google.com/go/go1.23.5.linux-amd64.tar.gz | sudo tar -C /usr/local -zxvf -

# Add Go environment variables
cat <<'EOF' >> $HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source $HOME/.profile

echo "✅ Go installed:"
go version

# Step 3: Download and extract Lumera binary
echo "========================================="
echo " Step 3: Download and extract Lumera    "
echo "========================================="
echo "📦 Downloading and setting up Lumera..."
cd $HOME
wget -q https://github.com/LumeraProtocol/lumera/releases/download/v0.4.1/lumera_v0.4.1_linux_amd64.tar.gz
tar -xvf lumera_v0.4.1_linux_amd64.tar.gz
rm lumera_v0.4.1_linux_amd64.tar.gz install.sh

# Move shared library and binary
sudo mv libwasmvm.x86_64.so /usr/lib/
chmod +x lumerad
mkdir -p $HOME/go/bin
mv lumerad $HOME/go/bin/

echo "✅ Lumera version:"
lumerad version

# Step 4: Initialize node
echo "========================================="
echo "         Step 4: Initialize node         "
echo "========================================="
read -p "📝 Enter your node name: " NODE_NAME
lumerad init "$NODE_NAME" --chain-id=lumera-testnet-1

# Step 5: Download genesis and addrbook
echo "========================================="
echo "   Step 5: Download genesis and addrbook "
echo "========================================="
echo "🌐 Downloading genesis and addrbook..."
curl -Ls https://ss-t.lumera.nodestake.org/genesis.json > $HOME/.lumera/config/genesis.json 
curl -Ls https://ss-t.lumera.nodestake.org/addrbook.json > $HOME/.lumera/config/addrbook.json

# Step 6: Create systemd service
echo "========================================="
echo "      Step 6: Create systemd service     "
echo "========================================="
echo "⚙️ Setting up systemd service..."
sudo tee /etc/systemd/system/lumerad.service > /dev/null <<EOF
[Unit]
Description=Lumera Daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which lumerad) start
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable lumerad

# Step 7: Download snapshot
echo "========================================="
echo "    Step 7: Download snapshot data       "
echo "========================================="
echo "📦 Downloading and extracting snapshot..."
SNAP_NAME=$(curl -s https://ss-t.lumera.nodestake.org/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
curl -L https://ss-t.lumera.nodestake.org/${SNAP_NAME} | lz4 -c -d - | tar -x -C $HOME/.lumera

# Step 8: Start the service
echo "========================================="
echo "        Step 8: Start Lumera Service     "
echo "========================================="
echo "🚀 Starting lumerad service..."
sudo systemctl restart lumerad

# Step 9: Finish
echo "========================================="
echo "✅ Lumera installation complete!"
echo "📄 To view logs, run:"
echo "   journalctl -u lumerad -f -o cat"
echo "========================================="

# Tail logs
journalctl -u lumerad -f -o cat
