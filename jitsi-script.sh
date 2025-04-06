#!/bin/bash

# Prompt user for domain and email
echo "Enter your domain (e.g., meet.example.com):"
read DOMAIN
echo "Enter your email for Let's Encrypt notifications:"
read EMAIL

# Update and install necessary packages
sudo apt update
sudo apt install -y gnupg2 nginx-full apt-transport-https curl sudo

# Ensure the 'universe' repository is enabled (for Ubuntu systems)
sudo apt-add-repository universe
sudo apt update

# Set the system's hostname
sudo hostnamectl set-hostname "$DOMAIN"
echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts

# Add the Prosody repository
echo "deb http://packages.prosody.im/debian $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
sudo apt install -y lua5.2

# Add the Jitsi package repository
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jitsi-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
sudo apt update

# Install Jitsi Meet
sudo apt install -y jitsi-meet

# Configure Let's Encrypt SSL certificate
# sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh

# copy the ui element
sudo cp ./fonts /usr/share/jitsi-meet/
sudo cp ./all.css /usr/share/jitsi-meet/css

# Restart services to apply changes
sudo systemctl restart prosody
sudo systemctl restart jicofo
sudo systemctl restart jitsi-videobridge2
sudo systemctl restart nginx

echo "Jitsi Meet installation completed. Access it at https://$DOMAIN"
