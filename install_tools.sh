#!/bin/bash

set -e

# Save original user if running as root
if [ "$EUID" -eq 0 ]; then
  if [ -n "$SUDO_USER" ]; then
    ORIGINAL_USER="$SUDO_USER"
  else
    read -p "Enter the username to add to sudo group: " ORIGINAL_USER
  fi
else
  echo "❌ Please run this script as root (use su or sudo)."
  exit 1
fi

# 
# --- Install prerequisites ---
echo "Installing prerequisites..."
sudo apt update
sudo apt install -y \
  wget \
  curl \
  gnupg \
  lsb-release \
  ca-certificates \
  passwd \
  util-linux

echo "export PATH=\$PATH:/usr/sbin" >> ~/.bashrc
source ~/.bashrc
echo "✅ /usr/sbin added to PATH in ~/.bashrc"

echo "✅ Adding user '$ORIGINAL_USER' to sudo group..."
usermod -aG sudo "$ORIGINAL_USER"
echo "User '$ORIGINAL_USER' added to sudo group."

#echo "Updating system packages..."
#sudo apt update && sudo apt upgrade -y

# --- Install Git ---
echo "Installing Git..."
sudo apt install -y git
echo -n "Git version: "
git --version

# --- Install Google Chrome ---
echo "Installing Google Chrome..."
wget -q -O google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome.deb
rm google-chrome.deb
echo -n "Google Chrome version: "
google-chrome --version || google-chrome-stable --version
echo "✅ Google Chrome installed successfully."


# --- Install Visual Studio Code ---
echo "Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
rm microsoft.gpg
sudo apt update
sudo apt install -y code
echo -n "VS Code version: "
code --version | head -n 1
echo "✅ Visual Studio Code installed successfully."

# --- Install Docker ---
echo "Installing Docker..."
sudo apt install -y     ca-certificates     curl     gnupg     lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo   "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg]   https://download.docker.com/linux/ubuntu   jammy stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$ORIGINAL_USER"
echo "✅ Docker installed successfully."
echo "✅ User '$ORIGINAL_USER' added to Docker group."

# --- Enable Docker ---
echo "Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker
echo -n "Docker version: "
docker --version
echo "✅ enabled successfully."


# --- Docker Compose (Standalone) ---
echo "Installing Docker-Compose (standalone binary)..."
DOCKER_COMPOSE_VERSION="2.24.5"  # Update as needed
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo -n "Docker Compose version: "
docker-compose --version
echo "✅ Docker-Compose installed successfully."

echo "all job done, will re-login to apply changes."
exec su -l $USER

echo "✅ All software installed and verified successfully."

