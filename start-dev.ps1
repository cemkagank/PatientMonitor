# Windows Development Startup Script
# This script gets the local IP address, updates ip.ts, starts the server, and launches Expo

# Initialize server process variable
$script:serverProcess = $null

# Cleanup function
function Cleanup {
    if ($script:serverProcess -and -not $script:serverProcess.HasExited) {
        Write-Host "`nStopping server (PID: $($script:serverProcess.Id))..." -ForegroundColor Yellow
        Stop-Process -Id $script:serverProcess.Id -Force -ErrorAction SilentlyContinue
        Write-Host "Server stopped." -ForegroundColor Green
    }
}

try {
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
    $wifiProfile = $null
    try {
        $wifiProfile = netsh wlan show profiles 2>$null | Select-String -Pattern "eduroam|public|guest" -CaseSensitive:$false
    } catch {
        # netsh command may fail, ignore
    }
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
# Build the file content - using string concatenation to avoid PowerShell backtick escaping issues
$ipTsContent = "// Server IP Address Configuration`r`n"
$ipTsContent += "// Update this value when the server IP changes`r`n"
$ipTsContent += "export const SERVER_IP = `"$ipAddress`"; // YAREN BURAYI DEĞİŞTİRECEKSİN <----------`r`n"
$ipTsContent += "export const SERVER_PORT = `"3000`";`r`n"
# Template literal: backtick needs to be escaped in PowerShell (use double backtick)
$templateStart = [char]96  # backtick character
$ipTsContent += "export const SERVER_URL = $templateStart" + "http://`${SERVER_IP}:`${SERVER_PORT}$templateStart;`r`n"
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

# Check if node is available
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodePath) {
    Write-Host "Error: Node.js not found. Please install Node.js and add it to PATH." -ForegroundColor Red
    exit 1
}

# Start server in a new window
try {
    $serverDir = Join-Path $PSScriptRoot "server"
    
    # Check if server has node_modules
    $serverNodeModules = Join-Path $serverDir "node_modules"
    if (-not (Test-Path $serverNodeModules)) {
        Write-Host "Installing server dependencies..." -ForegroundColor Yellow
        Push-Location $serverDir
        npm install
        Pop-Location
    }
    
    # Start server with correct working directory
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "node"
    $startInfo.Arguments = "server.js"
    $startInfo.WorkingDirectory = $serverDir
    $startInfo.UseShellExecute = $true
    $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
    
    $script:serverProcess = [System.Diagnostics.Process]::Start($startInfo)
    
    if (-not $script:serverProcess) {
        throw "Failed to start server process"
    }
    
    Write-Host "Server started (PID: $($script:serverProcess.Id))" -ForegroundColor Green
    Write-Host "Server running at: http://localhost:3000/data" -ForegroundColor Cyan
    Write-Host "Server accessible at: http://$ipAddress:3000/data" -ForegroundColor Cyan
    Write-Host "Working directory: $serverDir" -ForegroundColor Gray
    
    # Wait a bit for server to start (longer wait for serial port initialization)
    Write-Host "Waiting for server to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Check if server is actually running (retry a few times)
    $maxRetries = 5
    $retryCount = 0
    $serverResponding = $false
    
    while ($retryCount -lt $maxRetries -and -not $serverResponding) {
        try {
            $null = Invoke-WebRequest -Uri "http://localhost:3000/data" -TimeoutSec 2 -ErrorAction Stop
            $serverResponding = $true
            Write-Host "Server is responding correctly" -ForegroundColor Green
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "Waiting for server... (attempt $retryCount/$maxRetries)" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            } else {
                Write-Host "Warning: Server may not be responding. Check the server window for errors." -ForegroundColor Yellow
                Write-Host "Common issues:" -ForegroundColor Yellow
                Write-Host "  - Serial port (COM3) may not be available" -ForegroundColor White
                Write-Host "  - Check if Arduino is connected" -ForegroundColor White
                Write-Host "  - Server may still be starting..." -ForegroundColor White
            }
        }
    }
} catch {
    Write-Host "Error starting server: $_" -ForegroundColor Red
    Write-Host "Make sure Node.js is installed and server.js exists." -ForegroundColor Yellow
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Start Expo
Write-Host ""
Write-Host "[4/4] Starting Expo..." -ForegroundColor Yellow
Write-Host ""

# Change to project directory
Set-Location $PSScriptRoot

# Check if npx is available
$npxPath = Get-Command npx -ErrorAction SilentlyContinue
if (-not $npxPath) {
    Write-Host "Error: npx not found. Please install Node.js and npm." -ForegroundColor Red
    Cleanup
    exit 1
}

# Start Expo
Write-Host "Starting Expo development server..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop both server and Expo" -ForegroundColor Yellow
Write-Host ""

try {
    npx expo start
} catch {
    Write-Host "Error starting Expo: $_" -ForegroundColor Red
    Cleanup
    exit 1
}

# Cleanup: Kill server when script exits normally
Cleanup
Write-Host "Done!" -ForegroundColor Green
} finally {
    # Ensure cleanup runs even if script is interrupted
    Cleanup
}

