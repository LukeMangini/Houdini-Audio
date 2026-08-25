# Requires Run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please re-run PowerShell as Administrator!"
    Exit
}

$ErrorActionPreference = "Stop"
Write-Host "=== Starting Houdini Audio Deployment ===" -ForegroundColor Cyan

# 1. Directories
$vstDir   = "C:\Program Files\VSTPlugins\ReaPlugs"
$eqApoDir = "C:\Program Files\EqualizerAPO"
$temp     = "$env:TEMP\audio_installer"

New-Item -ItemType Directory -Force -Path $vstDir, $temp | Out-Null

# 2. Install Equalizer APO via Winget
Write-Host "[1/5] Installing Equalizer APO..." -ForegroundColor Green
winget install --id EqualizerAPO.EqualizerAPO -e --accept-package-agreements --accept-source-agreements --silent

# 3. Install VB-Audio Cable
Write-Host "[2/5] Installing VB-Audio Virtual Cable..." -ForegroundColor Green
$vbZip = "$temp\vbcable.zip"
Invoke-WebRequest -Uri "https://download.vb-audio.com/Download_ZIP/VBCABLE_Driver_Pack43.zip" -OutFile $vbZip
Expand-Archive -Path $vbZip -DestinationPath "$temp\vbcable" -Force
Start-Process -FilePath "$temp\vbcable\VBCABLE_Setup_x64.exe" -ArgumentList "-i -h" -Wait

# 4. Install ReaPlugs Suite
Write-Host "[3/5] Installing ReaPlugs Core..." -ForegroundColor Green
$reaInstaller = "$temp\reaplugs_setup.exe"
Invoke-WebRequest -Uri "https://www.reaper.fm/reaplugs/reaplugs236_x64-install.exe" -OutFile $reaInstaller
Start-Process -FilePath $reaInstaller -ArgumentList "/S" -Wait

# 5. Download Custom VSTs and EQ Target from GitHub
Write-Host "[4/5] Pulling Custom VST Plugins & BO7 Target File..." -ForegroundColor Green
$baseUrl = "https://raw.githubusercontent.com/LukeMangini/Houdini-Audio/main"

Invoke-WebRequest -Uri "$baseUrl/LoudMax64.dll" -OutFile "$vstDir\LoudMax64.dll"
Invoke-WebRequest -Uri "$baseUrl/atk_spatial_engine_bravo_v2_0_0.dll" -OutFile "$vstDir\atk_spatial_engine_bravo_v2_0_0.dll"
Invoke-WebRequest -Uri "$baseUrl/BO7_Target_V5.txt" -OutFile "$eqApoDir\config\BO7_Target_V5.txt"

# 6. Build Processing Chain config.txt
Write-Host "[5/5] Building processing chain..." -ForegroundColor Green
$configContent = @"
Preamp: -5.20 dB
VSTPlugin: C:\Program Files\VSTPlugins\ReaPlugs\atk_spatial_engine_bravo_v2_0_0.dll
VSTPlugin: C:\Program Files\VSTPlugins\ReaPlugs\reacomp-standalone.dll
Include: C:\Program Files\EqualizerAPO\config\BO7_Target_V5.txt
VSTPlugin: C:\Program Files\VSTPlugins\ReaPlugs\LoudMax64.dll
Preamp: -5.70 dB
"@

Set-Content -Path "$eqApoDir\config\config.txt" -Value $configContent

# 7. Device Selector
Write-Host "`nLauncher Complete!" -ForegroundColor Green
Write-Host "--> Select your output device in the window, click OK, and REBOOT." -ForegroundColor Yellow

Start-Process "$eqApoDir\Configurator.exe" -Wait
Remove-Item -Path $temp -Recurse -Force
