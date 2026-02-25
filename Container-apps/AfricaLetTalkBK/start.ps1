#!/usr/bin/env pwsh

Write-Host "🚀 Starting AfricaLetsTalk..." -ForegroundColor Cyan

# Start services
docker compose up -d

Write-Host ""
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Check status
Write-Host ""
docker compose ps

Write-Host ""
Write-Host "✅ Application is running!" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application at:" -ForegroundColor White
Write-Host "  Frontend: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  Backend API: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commands:" -ForegroundColor White
Write-Host "  View logs:    docker compose logs -f" -ForegroundColor Gray
Write-Host "  Stop app:     docker compose down" -ForegroundColor Gray
Write-Host "  Restart:      docker compose restart" -ForegroundColor Gray
