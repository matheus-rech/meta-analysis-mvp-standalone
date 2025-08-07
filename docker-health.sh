#!/bin/bash

# Docker Health Check Script for Meta-Analysis MVP
# This script checks the health status of the running container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONTAINER_NAME="meta-analysis-mvp"

echo "🏥 Checking Health Status of Meta-Analysis MVP..."
echo "================================================"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}❌ Container ${CONTAINER_NAME} is not running.${NC}"
    echo -e "${YELLOW}💡 Start it with: ./docker-run.sh${NC}"
    exit 1
fi

# Get container health status
HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null || echo "none")

echo -e "${BLUE}📊 Container Status:${NC}"
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Status}}\t{{.Ports}}"
echo ""

# Check health status
case $HEALTH_STATUS in
    healthy)
        echo -e "${GREEN}✅ Container is HEALTHY${NC}"
        
        # Show recent health check logs
        echo -e "\n${BLUE}📝 Recent Health Check Logs:${NC}"
        docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' ${CONTAINER_NAME} | tail -3
        
        # Test R functionality
        echo -e "\n${BLUE}🔬 Testing R functionality:${NC}"
        docker exec ${CONTAINER_NAME} Rscript -e "packageVersion('meta'); packageVersion('metafor')" 2>/dev/null && \
            echo -e "${GREEN}✅ R packages are loaded correctly${NC}" || \
            echo -e "${RED}❌ R packages check failed${NC}"
        
        # Test Node.js functionality
        echo -e "\n${BLUE}🔬 Testing Node.js functionality:${NC}"
        docker exec ${CONTAINER_NAME} node -e "console.log('Node.js version:', process.version)" && \
            echo -e "${GREEN}✅ Node.js is running correctly${NC}" || \
            echo -e "${RED}❌ Node.js check failed${NC}"
        ;;
    
    starting)
        echo -e "${YELLOW}⏳ Container health check is STARTING...${NC}"
        echo "Please wait a moment and run this script again."
        ;;
    
    unhealthy)
        echo -e "${RED}❌ Container is UNHEALTHY${NC}"
        echo -e "\n${RED}Error logs:${NC}"
        docker logs --tail 20 ${CONTAINER_NAME}
        echo -e "\n${YELLOW}💡 Try restarting the container: docker restart ${CONTAINER_NAME}${NC}"
        exit 1
        ;;
    
    none)
        echo -e "${YELLOW}⚠️  No health check configured or container doesn't support it${NC}"
        # Basic connectivity test
        echo -e "\n${BLUE}🔬 Running basic checks:${NC}"
        docker exec ${CONTAINER_NAME} echo "Container is responsive" &>/dev/null && \
            echo -e "${GREEN}✅ Container is responsive${NC}" || \
            echo -e "${RED}❌ Container is not responsive${NC}"
        ;;
    
    *)
        echo -e "${RED}❓ Unknown health status: ${HEALTH_STATUS}${NC}"
        exit 1
        ;;
esac

# Show resource usage
echo -e "\n${BLUE}📈 Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" ${CONTAINER_NAME}

echo -e "\n${GREEN}✨ Health check complete!${NC}"
