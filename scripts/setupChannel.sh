#!/bin/bash
set -e

echo "=== SETUP CHANNEL DAN JOIN PEERS ==="

# === Konfigurasi Umum ===
CHANNEL_NAME="sick-letter-channel"
FABRIC_CFG_PATH=~/Documents/Capstone-Project
BIN_PATH=~/Documents/Capstone-Project/fabric-samples/bin
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

export PATH=$BIN_PATH:$PATH
export FABRIC_CFG_PATH=$FABRIC_CFG_PATH

# === Fungsi Validasi ===
check_success() {
  if [ $? -ne 0 ]; then
    echo "❌ ERROR: $1 gagal"
    exit 1
  fi
}

# === Fungsi Join Peer ===
join_peer() {
  ORG=$1
  PORT=$2
  MSP=$3

  echo "➡️ Peer $ORG join channel..."

  docker exec -e CORE_PEER_LOCALMSPID="$MSP" \
              -e CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp" \
              -e CORE_PEER_ADDRESS="peer0.$ORG.example.com:$PORT" \
              -e CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/tls/ca.crt" \
              cli peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

  check_success "Peer $ORG join channel"
}

# === Validasi File channel.tx dan genesis.block ===
if [ ! -f ./channel-artifacts/channel.tx ]; then
  echo "⚠️ File channel.tx tidak ditemukan. Membuat ulang..."
  configtxgen -profile ThreeOrgsChannel \
    -outputCreateChannelTx ./channel-artifacts/channel.tx \
    -channelID $CHANNEL_NAME
  check_success "Generate channel.tx"
fi

if [ ! -f ./channel-artifacts/orderer.genesis.block ]; then
  echo "⚠️ File orderer.genesis.block tidak ditemukan. Membuat ulang..."
  configtxgen -profile ThreeOrgsOrdererGenesis \
    -channelID system-channel \
    -outputBlock ./channel-artifacts/orderer.genesis.block
  check_success "Generate orderer.genesis.block"
fi

# === 1. Membuat Channel ===
echo "🛠️ Membuat channel $CHANNEL_NAME..."
docker exec cli peer channel create \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  -c $CHANNEL_NAME \
  -f ./channel-artifacts/channel.tx \
  --outputBlock ./channel-artifacts/$CHANNEL_NAME.block \
  --tls --cafile $ORDERER_CA
check_success "Channel creation"

# === 2. Join Semua Peer ===
join_peer "klinik" 7051 "KlinikMSP"
join_peer "akademik" 9051 "AkademikMSP"
join_peer "mahasiswa" 8051 "MahasiswaMSP"

echo "✅ Semua peer berhasil join channel '$CHANNEL_NAME'"
