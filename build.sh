#!/bin/bash

# Script to build Hugo site using Docker

# Set colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed.${NC}"
    echo "Please install Docker Compose first: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "./Dockerfile" ]; then
    echo -e "${RED}Error: Dockerfile not found in current directory.${NC}"
    exit 1
fi

# Display menu
echo -e "${BLUE}Hugo Docker Build Tool${NC}"
echo "--------------------"
echo "1. Build the site (creates static files in 'public' directory)"
echo "2. Serve the site locally (http://localhost:1313)"
echo "3. Get a shell in the container"
echo "4. Build Docker image"
echo "q. Quit"
echo ""

read -p "Select an option: " option

case $option in
    1)
        echo -e "${GREEN}Building Hugo site...${NC}"
        docker-compose run --rm hugo build
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Build successful! Site generated in ./public directory${NC}"
        else
            echo -e "${RED}Build failed. See error messages above.${NC}"
        fi
        ;;
    2)
        echo -e "${GREEN}Starting Hugo server...${NC}"
        echo -e "Site will be available at ${BLUE}http://localhost:1313${NC}"
        echo "Press Ctrl+C to stop the server"
        docker-compose up
        ;;
    3)
        echo -e "${GREEN}Starting shell in container...${NC}"
        docker-compose run --rm hugo shell
        ;;
    4)
        echo -e "${GREEN}Building Docker image...${NC}"
        docker-compose build
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker image built successfully!${NC}"
        else
            echo -e "${RED}Docker image build failed. See error messages above.${NC}"
        fi
        ;;
    q|Q)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac