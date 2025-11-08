#!/bin/bash

# Exit immediately if any command fails
set -e

echo "=== STARTING HYPERLEDGER FABRIC NETWORK ==="

# Set Fabric binaries path
export PATH=~/Documents/Capstone-Project/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=~/Documents/Capstone-Project

# Error checking function
handle_error() {
    echo "ERROR: $1"
    echo "Script failed. Check logs above for details."
    exit 1
}

# Check required commands
check_command() {
    if ! command -v $1 &> /dev/null; then
        handle_error "Command $1 not found. Please install Fabric binaries first."
    fi
}

# Function to check container status with retry
check_container_with_retry() {
    local container_name=$1
    local max_attempts=5
    local attempt=1
    
    echo "Checking $container_name..."
    
    while [ $attempt -le $max_attempts ]; do
        if [ "$(docker ps -q -f name=$container_name)" ]; then
            echo "✓ $container_name is running"
            return 0
        fi
        echo "Attempt $attempt: $container_name not ready yet..."
        sleep 10
        ((attempt++))
    done
    
    handle_error "$container_name failed to start after $max_attempts attempts"
}

echo "Checking Fabric binaries..."
check_command cryptogen
check_command configtxgen

cryptogen version || handle_error "Cryptogen version check failed"
configtxgen --version || handle_error "Configtxgen version check failed"

# Clean up previous materials
echo "Cleaning up previous materials..."
sudo rm -rf ./crypto-config || echo "Warning: Could not remove crypto-config"
sudo rm -rf ./channel-artifacts || echo "Warning: Could not remove channel-artifacts"
mkdir -p channel-artifacts || handle_error "Failed to create channel-artifacts directory"

# Generate crypto materials
echo "Generating crypto materials..."
cryptogen generate --config=./crypto-config.yaml || handle_error "Failed to generate crypto materials"

# Generate genesis block
echo "Generating genesis block..."
configtxgen -profile ThreeOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block || handle_error "Failed to generate genesis block"

# Generate channel transaction  
echo "Generating channel transaction..."
configtxgen -profile ThreeOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID sick-letter-channel || handle_error "Failed to generate channel transaction"

# Stop any running containers first
echo "Stopping any running containers..."
docker-compose down || echo "No running containers to stop"

# Start network
echo "Starting Docker containers..."
docker-compose up -d || handle_error "Failed to start Docker containers"

# Wait for network to start with individual checks
echo "Waiting for containers to start..."
sleep 10

# Check each container individually
check_container_with_retry "orderer.example.com"
check_container_with_retry "peer0.klinik.example.com" 
check_container_with_retry "peer0.akademik.example.com"
check_container_with_retry "peer0.mahasiswa.example.com"
check_container_with_retry "cli"

echo "=== NETWORK STARTED SUCCESSFULLY ==="
echo "Orderer: localhost:7050"
echo "Peer Klinik: localhost:7051"
echo "Peer Akademik: localhost:9051" 
echo "Peer Mahasiswa: localhost:8051"

# Final check
echo "Performing final health check..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"