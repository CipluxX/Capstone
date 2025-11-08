#!/bin/bash

set -e

echo "=== SETUP CHANNEL DAN JOIN PEERS ==="

# Export environment variables
export PATH=~/Documents/Capstone-Project/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=~/Documents/Capstone-Project

# Set environment for each org
export CORE_PEER_LOCALMSPID="KlinikMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/klinik.example.com/users/Admin@klinik.example.com/msp
export CORE_PEER_ADDRESS=peer0.klinik.example.com:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/klinik.example.com/peers/peer0.klinik.example.com/tls/ca.crt
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Function untuk check command success
check_success() {
    if [ $? -ne 0 ]; then
        echo "ERROR: $1 failed"
        exit 1
    fi
}

# Wait for orderer to be ready
echo "Menunggu orderer siap..."
sleep 10

# 1. Create channel
echo "1. Membuat channel sick-letter-channel..."
docker exec cli peer channel create -o orderer.example.com:7050 -c sick-letter-channel \
    --file ./channel-artifacts/channel.tx \
    --tls --cafile $ORDERER_CA \
    --outputBlock sick-letter-channel.block
check_success "Channel creation"

# 2. Peer Klinik join channel
echo "2. Peer Klinik join channel..."
docker exec cli peer channel join -b sick-letter-channel.block
check_success "Peer Klinik join channel"

# 3. Peer Akademik join channel  
echo "3. Peer Akademik join channel..."
export CORE_PEER_LOCALMSPID="AkademikMSP"
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/akademik.example.com/users/Admin@akademik.example.com/msp
export CORE_PEER_ADDRESS=peer0.akademik.example.com:9051
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/akademik.example.com/peers/peer0.akademik.example.com/tls/ca.crt

docker exec cli peer channel join -b sick-letter-channel.block
check_success "Peer Akademik join channel"

# 4. Peer Mahasiswa join channel
echo "4. Peer Mahasiswa join channel..."
export CORE_PEER_LOCALMSPID="MahasiswaMSP"
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mahasiswa.example.com/users/Admin@mahasiswa.example.com/msp
export CORE_PEER_ADDRESS=peer0.mahasiswa.example.com:8051
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mahasiswa.example.com/peers/peer0.mahasiswa.example.com/tls/ca.crt

docker exec cli peer channel join -b sick-letter-channel.block
check_success "Peer Mahasiswa join channel"

echo "=== CHANNEL SETUP BERHASIL ==="
echo "Channel 'sick-letter-channel' berhasil dibuat dan semua peers telah join"