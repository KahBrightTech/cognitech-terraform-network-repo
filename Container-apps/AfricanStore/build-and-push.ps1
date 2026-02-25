#!/usr/bin/env pwsh
# Build, tag, and push all Docker images to Docker Hub
# Usage: .\build-and-push.ps1 <your-dockerhub-username>

param(
    [Parameter(Mandatory=$true)]
    [string]$DockerHubUsername
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Building and pushing African Wear E-commerce images to Docker Hub" -ForegroundColor Cyan
Write-Host "Docker Hub Username: $DockerHubUsername" -ForegroundColor Yellow
Write-Host ""

# Service definitions
$services = @(
    @{Name="auth-service"; Path="./auth-service"},
    @{Name="products-service"; Path="./products-service"},
    @{Name="cart-service"; Path="./cart-service"},
    @{Name="frontend"; Path="./frontend"}
)

# Login to Docker Hub
Write-Host "📦 Logging in to Docker Hub..." -ForegroundColor Cyan
docker login

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker login failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker login successful!" -ForegroundColor Green
Write-Host ""

# Build, tag, and push each service
foreach ($service in $services) {
    $serviceName = $service.Name
    $servicePath = $service.Path
    $imageTag = "${DockerHubUsername}/africanwear-${serviceName}:latest"
    
    Write-Host "🔨 Building $serviceName..." -ForegroundColor Cyan
    docker build -t $imageTag $servicePath
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build $serviceName" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Built $serviceName successfully" -ForegroundColor Green
    
    Write-Host "⬆️  Pushing $imageTag to Docker Hub..." -ForegroundColor Cyan
    docker push $imageTag
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to push $serviceName" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Pushed $serviceName successfully" -ForegroundColor Green
    Write-Host ""
}

Write-Host "🎉 All images built and pushed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 To deploy using these images, update docker-compose.yml:" -ForegroundColor Yellow
Write-Host "   Replace 'build: ./service-name' with 'image: $DockerHubUsername/africanwear-service-name:latest'" -ForegroundColor Yellow
Write-Host ""
Write-Host "Images pushed:" -ForegroundColor Cyan
foreach ($service in $services) {
    Write-Host "  - ${DockerHubUsername}/africanwear-$($service.Name):latest" -ForegroundColor White
}
