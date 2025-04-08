#!/bin/bash

# Exit immediately on error in any piped command
set -o pipefail

# Prompt user for domain and email
echo "Enter your domain (e.g., meet.example.com):"
read DOMAIN
echo "Enter your email for Let's Encrypt notifications:"
read EMAIL

# Function to check for errors
check_error() {
  if [ $? -ne 0 ]; then
    echo "❌ Error occurred at: $1. Exiting."
  fi
}

# Update and install necessary packages
echo "🔄 Updating packages..."
sudo apt update
check_error "apt update"

echo "📦 Installing base packages..."
sudo apt install -y gnupg2 nginx-full apt-transport-https curl sudo software-properties-common
check_error "base package installation"

# Ensure the 'universe' repository is enabled (for Ubuntu systems)
echo "📚 Enabling universe repo..."
sudo apt-add-repository universe
check_error "adding universe repository"
sudo apt update
check_error "apt update after adding universe"

# Set the system's hostname
echo "🖥️ Setting hostname to $DOMAIN..."
sudo hostnamectl set-hostname "$DOMAIN"
check_error "setting hostname"
echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts >/dev/null
check_error "updating /etc/hosts"

# Add the Prosody repository
echo "📦 Adding Prosody repo..."
wget -qO- https://prosody.im/files/prosody-debian-packages.key | sudo apt-key add -
check_error "adding Prosody GPG key"
echo "deb http://packages.prosody.im/debian $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list
check_error "adding Prosody source"
sudo apt install -y lua5.2
check_error "installing lua5.2"

# Add the Jitsi package repository
echo "📦 Adding Jitsi repo..."
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jitsi-keyring.gpg
check_error "adding Jitsi key"
echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
check_error "adding Jitsi source"
sudo apt update
check_error "apt update for Jitsi"

# Install Jitsi Meet
echo "⚙️ Installing Jitsi Meet..."
sudo apt install -y jitsi-meet
check_error "installing Jitsi Meet"

# Copy custom UI files if they exist
if [ -f "./all.css" ]; then
  echo "🎨 Copying all.css..."
  sudo cp ./all.css /usr/share/jitsi-meet/css/
  check_error "[copying all.css]"
fi

if [ -d "./fonts" ]; then
  echo "🖋️ Copying fonts directory..."
  sudo cp -r ./fonts /usr/share/jitsi-meet/
  check_error "[copying fonts]"
fi

if [ -d "./prosody-plugins" ]; then
  echo "🖋️ Copying fonts directory..."
  sudo cp -r ./prosody-plugins /usr/share/jitsi-meet/
  check_error "[copying the prosody plugins]"
fi

# Call prosody configuration modification
DOMAIN="$DOMAIN" bash ./config-modification-script.sh

# Restart services to apply changes
echo "🔁 Restarting services..."
sudo systemctl restart prosody
check_error "restarting prosody"

sudo systemctl restart jicofo
check_error "restarting jicofo"

sudo systemctl restart jitsi-videobridge2
check_error "restarting videobridge2"

sudo systemctl restart nginx
check_error "restarting nginx"

echo "✅ Jitsi Meet installation completed. Access it at https://$DOMAIN"
