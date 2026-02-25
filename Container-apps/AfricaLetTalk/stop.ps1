#!/usr/bin/env pwsh

Write-Host "🛑 Stopping AfricaLetsTalk..." -ForegroundColor Yellow

docker compose down

Write-Host ""
Write-Host "✅ All services stopped." -ForegroundColor Green
