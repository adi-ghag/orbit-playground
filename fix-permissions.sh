#!/bin/bash

echo "Fixing file permissions for Docker containers..."

# Fix ownership of chainConfig directory
sudo chown -R $USER:$USER chainConfig/

# Make directories writable for Docker containers
# Using 777 for local development (containers need to write here)
sudo chmod -R 777 chainConfig/

# Create DAS data directory if it doesn't exist
mkdir -p chainDasData

# Make DAS data directory writable
sudo chmod -R 777 chainDasData/
sudo chown -R $USER:$USER chainDasData/

echo "✓ Permissions fixed!"
echo ""
echo "Now you can run: yarn start-node"
