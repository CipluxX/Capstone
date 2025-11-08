#!/bin/bash

case "$1" in
    "soft")
        echo "Soft stop - preserving data..."
        docker-compose down
        ;;
    "hard")
        echo "Hard stop - removing containers and volumes..."
        docker-compose down -v
        docker rm -f $(docker ps -aq --filter "name=dev-*") 2>/dev/null
        ;;
    "clean")
        echo "Clean stop - removing everything..."
        docker-compose down -v
        docker rm -f $(docker ps -aq --filter "name=dev-*") 2>/dev/null
        sudo rm -rf ./crypto-config ./channel-artifacts
        docker system prune -f
        ;;
    *)
        echo "Usage: $0 {soft|hard|clean}"
        echo "  soft  - Stop containers, keep data"
        echo "  hard  - Stop containers and remove volumes"  
        echo "  clean - Stop and remove everything"
        exit 1
        ;;
esac

echo "=== NETWORK STOPPED ==="