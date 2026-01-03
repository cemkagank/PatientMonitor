# Windows Development Startup Script
# This script gets the local IP address, updates ip.ts, starts the server, and launches Expo

Write-Host "=== Patient Monitoring App - Development Startup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get local IP address
Write-Host "[1/4] Getting local IP address..." -ForegroundColor Yellow

# Get the first active IPv4 address (excluding localhost)
$ipAddress = $null
$adapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.InterfaceAlias -notlike "*Loopback*"
} | Sort-Object InterfaceIndex

if ($adapters) {
    $ipAddress = $adapters[0].IPAddress
    $adapterName = $adapters[0].InterfaceAlias
    Write-Host "Found IP address: $ipAddress" -ForegroundColor Green
    Write-Host "Network adapter: $adapterName" -ForegroundColor Gray
    
    # Check if connected to eduroam or similar public networks
    $wifiProfile = netsh wlan show profiles | Select-String -Pattern "eduroam|public|guest" -CaseSensitive:$false
    if ($wifiProfile -or $adapterName -like "*eduroam*" -or $adapterName -like "*public*") {
        Write-Host ""
        Write-Host "⚠️  WARNING: Connected to a public/campus network (eduroam, etc.)" -ForegroundColor Yellow
        Write-Host "   Public networks often have 'Client Isolation' enabled." -ForegroundColor Yellow
        Write-Host "   Your mobile device may not be able to connect to this PC." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Solutions:" -ForegroundColor Cyan
        Write-Host "   1. Use a mobile hotspot (recommended)" -ForegroundColor White
        Write-Host "   2. Connect both devices to the same private WiFi network" -ForegroundColor White
        Write-Host "   3. Use USB tethering" -ForegroundColor White
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit 0
        }
    }
} else {
    Write-Host "Could not find IP address. Using default: 192.168.8.103" -ForegroundColor Yellow
    $ipAddress = "192.168.8.103"
}

# Step 2: Update ip.ts file
Write-Host ""
Write-Host "[2/4] Updating ip.ts file..." -ForegroundColor Yellow

$ipTsPath = Join-Path $PSScriptRoot "ip.ts"
$ipTsContent = "// Server IP Address Configuration`r`n"
$ipTsContent += "// Update this value when the server IP changes`r`n"
$ipTsContent += "export const SERVER_IP = `"$ipAddress`"; // YAREN BURAYI DEĞİŞTİRECEKSİN <----------`r`n"
$ipTsContent += "export const SERVER_PORT = `"3000`";`r`n"
$ipTsContent += "export const SERVER_URL = ``http://``$`{SERVER_IP}:``$`{SERVER_PORT}``;`r`n"
$ipTsContent += "`r`n"

try {
    Set-Content -Path $ipTsPath -Value $ipTsContent -Encoding UTF8
    Write-Host "ip.ts updated successfully with IP: $ipAddress" -ForegroundColor Green
} catch {
    Write-Host "Error updating ip.ts: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Start the server
Write-Host ""
Write-Host "[3/4] Starting server..." -ForegroundColor Yellow

$serverPath = Join-Path $PSScriptRoot "server\server.js"

if (-not (Test-Path $serverPath)) {
    Write-Host "Error: server.js not found at $serverPath" -ForegroundColor Red
    exit 1
}

# Start server in a new window
$serverProcess = Start-Process -FilePath "node" -ArgumentList $serverPath -PassThru -WindowStyle Normal
Write-Host "Server started (PID: $($serverProcess.Id))" -ForegroundColor Green
Write-Host "Server running at: http://localhost:3000/data" -ForegroundColor Cyan
Write-Host "Server accessible at: http://$ipAddress:3000/data" -ForegroundColor Cyan

# Wait a bit for server to start
Start-Sleep -Seconds 2

# Check if server is actually running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/data" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✓ Server is responding correctly" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Warning: Server may not be responding. Check the server window." -ForegroundColor Yellow
}

# Step 4: Start Expo
Write-Host ""
Write-Host "[4/4] Starting Expo..." -ForegroundColor Yellow
Write-Host ""

# Change to project directory
Set-Location $PSScriptRoot

# Start Expo
Write-Host "Starting Expo development server..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop both server and Expo" -ForegroundColor Yellow
Write-Host ""

npx expo start

# Cleanup: Kill server when script exits
Write-Host ""
Write-Host "Stopping server..." -ForegroundColor Yellow
Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
Write-Host "Done!" -ForegroundColor Green

