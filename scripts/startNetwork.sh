#!/bin/bash
set -e

echo "=== STARTING HYPERLEDGER FABRIC NETWORK ==="

export PATH=~/Documents/Capstone-Project/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=~/Documents/Capstone-Project

handle_error() {
    echo "ERROR: $1"
    exit 1
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        handle_error "Command $1 not found. Please install Fabric binaries first."
    fi
}

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

mkdir -p channel-artifacts

# Generate crypto materials only if missing
if [ ! -d "./crypto-config" ]; then
    echo "Generating crypto materials..."
    cryptogen generate --config=./crypto-config.yaml || handle_error "Failed to generate crypto materials"
else
    echo "✓ crypto-config already exists, skipping generation"
fi

# Generate genesis block only if missing
if [ ! -f "./channel-artifacts/orderer.genesis.block" ]; then
    echo "Generating genesis block..."
    configtxgen -profile ThreeOrgsOrdererGenesis \
        -channelID system-channel \
        -outputBlock ./channel-artifacts/orderer.genesis.block || handle_error "Failed to generate genesis block"
else
    echo "✓ orderer.genesis.block already exists, skipping generation"
fi

# Generate channel transaction only if missing
if [ ! -f "./channel-artifacts/channel.tx" ]; then
    echo "Generating channel transaction..."
    configtxgen -profile ThreeOrgsChannel \
        -outputCreateChannelTx ./channel-artifacts/channel.tx \
        -channelID sick-letter-channel || handle_error "Failed to generate channel transaction"
else
    echo "✓ channel.tx already exists, skipping generation"
fi

echo "Stopping any running containers..."
docker-compose down || echo "No running containers to stop"

echo "Starting Docker containers..."
docker-compose up -d || handle_error "Failed to start Docker containers"

echo "Waiting for containers to start..."
sleep 10

check_container_with_retry "orderer.example.com"
check_container_with_retry "peer0.klinik.example.com"
check_container_with_retry "peer0.akademik.example.com"
check_container_with_retry "peer0.mahasiswa.example.com"
check_container_with_retry "cli"

echo "=== NETWORK STARTED SUCCESSFULLY ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
