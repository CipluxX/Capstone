#!/bin/bash

set -e

MODE=$1

case "$MODE" in
  "soft")
    echo "🛑 Soft stop – stopping containers, preserving volumes and crypto materials..."
    docker-compose down
    ;;
  
  "hard")
    echo "🧹 Hard stop – stopping containers and removing volumes..."
    docker-compose down -v
    echo "🧼 Removing dev-* containers (if any)..."
    docker rm -f $(docker ps -aq --filter "name=dev-*") 2>/dev/null || true
    ;;
  
  "clean")
    echo "🔥 Clean stop – removing everything including crypto materials and artifacts..."
    docker-compose down -v
    echo "🧼 Removing dev-* containers (if any)..."
    docker rm -f $(docker ps -aq --filter "name=dev-*") 2>/dev/null || true
    echo "🗑️ Deleting crypto-config and channel-artifacts..."
    sudo rm -rf ./crypto-config ./channel-artifacts
    echo "🧽 Pruning unused Docker resources..."
    docker system prune -f
    ;;
  
  *)
    echo "❓ Usage: $0 {soft|hard|clean}"
    echo "  soft  – Stop containers, keep volumes and crypto"
    echo "  hard  – Stop containers and remove volumes"
    echo "  clean – Stop and remove everything (containers, volumes, crypto, artifacts)"
    exit 1
    ;;
esac

echo "✅ === NETWORK STOPPED SUCCESSFULLY ==="
