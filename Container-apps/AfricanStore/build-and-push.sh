#!/bin/bash
# Build, tag, and push all Docker images to Docker Hub
# Usage: ./build-and-push.sh <your-dockerhub-username>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <dockerhub-username>"
    exit 1
fi

DOCKERHUB_USERNAME=$1

echo "🚀 Building and pushing African Wear E-commerce images to Docker Hub"
echo "Docker Hub Username: $DOCKERHUB_USERNAME"
echo ""

# Login to Docker Hub
echo "📦 Logging in to Docker Hub..."
docker login

if [ $? -ne 0 ]; then
    echo "❌ Docker login failed!"
    exit 1
fi

echo "✅ Docker login successful!"
echo ""

# Service definitions
declare -A services
services=(
    ["auth-service"]="./auth-service"
    ["products-service"]="./products-service"
    ["cart-service"]="./cart-service"
    ["frontend"]="./frontend"
)

# Build, tag, and push each service
for service_name in "${!services[@]}"; do
    service_path="${services[$service_name]}"
    image_tag="${DOCKERHUB_USERNAME}/africanwear-${service_name}:latest"
    
    echo "🔨 Building $service_name..."
    docker build -t "$image_tag" "$service_path"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to build $service_name"
        exit 1
    fi
    
    echo "✅ Built $service_name successfully"
    
    echo "⬆️  Pushing $image_tag to Docker Hub..."
    docker push "$image_tag"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to push $service_name"
        exit 1
    fi
    
    echo "✅ Pushed $service_name successfully"
    echo ""
done

echo "🎉 All images built and pushed successfully!"
echo ""
echo "📝 To deploy using these images, update docker-compose.yml:"
echo "   Replace 'build: ./service-name' with 'image: $DOCKERHUB_USERNAME/africanwear-service-name:latest'"
echo ""
echo "Images pushed:"
for service_name in "${!services[@]}"; do
    echo "  - ${DOCKERHUB_USERNAME}/africanwear-${service_name}:latest"
done
