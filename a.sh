#!/bin/bash

set -e

# --- Helper function to run commands quietly but report errors ---
run_quietly() {
  "$@" > /dev/null 2>&1
  local status=$?
  if [ $status -ne 0 ]; then
    echo "❌ Error running: $*"
    exit $status
  fi
}

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

# --- Install prerequisites ---
echo "1. Installing prerequisites..."
run_quietly apt update
run_quietly apt install -y wget curl gnupg lsb-release ca-certificates passwd util-linux

echo "export PATH=\$PATH:/usr/sbin" >> ~/.bashrc
source ~/.bashrc
echo "2. ✅ /usr/sbin added to PATH in ~/.bashrc"

echo "3. ✅ Adding user '$ORIGINAL_USER' to sudo group..."
run_quietly usermod -aG sudo "$ORIGINAL_USER"
echo "4. User '$ORIGINAL_USER' added to sudo group."

# --- Install Git ---
echo "5. Installing Git..."
run_quietly apt install -y git
echo -n "Git version: "
git --version

# --- Install Google Chrome ---
echo "6. Installing Google Chrome..."
run_quietly wget -q -O google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
run_quietly apt install -y ./google-chrome.deb
rm google-chrome.deb
echo -n "Google Chrome version: "
google-chrome --version 2>/dev/null || google-chrome-stable --version

# --- Install Visual Studio Code ---
echo "7. Installing Visual Studio Code..."
run_quietly wget -q https://packages.microsoft.com/keys/microsoft.asc -O microsoft.asc
run_quietly gpg --dearmor -o microsoft.gpg microsoft.asc
run_quietly install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
run_quietly sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
rm microsoft.asc microsoft.gpg
run_quietly apt update
run_quietly apt install -y code
echo -n "VS Code version: "
code --version | head -n 1

# --- Install Docker ---
echo "8. Installing Docker..."
run_quietly apt install -y ca-certificates curl gnupg lsb-release
run_quietly mkdir -p /etc/apt/keyrings
run_quietly curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

run_quietly sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list'

run_quietly apt update
run_quietly apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
run_quietly usermod -aG docker "$ORIGINAL_USER"

# --- Enable Docker ---
echo "9. Enabling Docker service..."
run_quietly systemctl enable docker
run_quietly systemctl start docker
echo -n "Docker version: "
docker --version

# --- Docker Compose (Standalone) ---
echo "10. Installing Docker-Compose (standalone binary)..."
DOCKER_COMPOSE_VERSION="2.24.5"  # Update as needed
run_quietly curl -L "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
run_quietly chmod +x /usr/local/bin/docker-compose
echo -n "Docker Compose version: "
docker-compose --version

echo "11. ✅ Docker-Compose installed successfully. will re login to apply changes."
exec su -l "$USER"

echo "✅ All software installed and verified successfully."
