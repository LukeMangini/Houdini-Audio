# Requires Run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please re-run PowerShell as Administrator!"
    Exit
}

$ErrorActionPreference = "Stop"
Write-Host "=== Starting Custom Audio Chain Deployment ===" -ForegroundColor Cyan

# 1. Paths & Folders
$vstDir = "C:\Program Files\VSTPlugins\ReaPlugs"
$eqApoDir = "C:\Program Files\EqualizerAPO"
$temp = "$env:TEMP\audio_installer"

New-Item -ItemType Directory -Force -Path $vstDir, $temp | Out-Null

# 2. Install Core Software via Winget
Write-Host "[1/5] Installing Equalizer APO..." -ForegroundColor Green
winget install --id EqualizerAPO.EqualizerAPO -e --accept-package-agreements --accept-source-agreements --silent

# 3. Download & Install VB-Audio Cable
Write-Host "[2/5] Downloading VB-Audio Cable..." -ForegroundColor Green
$vbZip = "$temp\vbcable.zip"
Invoke-WebRequest -Uri "https://download.vb-audio.com/Download_ZIP/VBCABLE_Driver_Pack43.zip" -OutFile $vbZip
Expand-Archive -Path $vbZip -DestinationPath "$temp\vbcable" -Force
Start-Process -FilePath "$temp\vbcable\VBCABLE_Setup_x64.exe" -ArgumentList "-i -h" -Wait

# 4. Fetch Plugin DLLs & Custom Presets
Write-Host "[3/5] Pulling VST Plugins & Presets..." -ForegroundColor Green
# Replace these URLs with direct download links to your hosted DLLs/IEM EQ files (e.g. GitHub Raw, Dropbox, Cloud storage)
# Invoke-WebRequest -Uri "https://your-cloud.com/LoudMax64.dll" -OutFile "$vstDir\LoudMax64.dll"
# Invoke-WebRequest -Uri "https://your-cloud.com/atk_spatial_engine_bravo_v2_0_0.dll" -OutFile "$vstDir\atk_spatial_engine_bravo_v2_0_0.dll"
# Invoke-WebRequest -Uri "https://your-cloud.com/64_Audio_A6t_Filters.txt" -OutFile "C:\Program Files\EqualizerAPO\config\64_Audio_A6t_Filters.txt"

# 5. Build the Exact Config Chain
Write-Host "[4/5] Writing config.txt processing chain..." -ForegroundColor Green
$configContent = @"
Preamp: -5.20 dB
VSTPlugin: C:\Program Files\VSTPlugins\ReaPlugs\atk_spatial_engine_bravo_v2_0_0.dll
VSTPlugin: C:\Program Files\VSTPlugins\ReaPlugs\reacomp-standalone.dll
Include: C:\Program Files\EqualizerAPO\config\64_Audio_A6t_Filters.txt
VSTPlugin: C:\Program Files\VSTPlugins\ReaPlugs\LoudMax64.dll
Preamp: -5.70 dB
"@

Set-Content -Path "$eqApoDir\config\config.txt" -Value $configContent

# 6. Device Selector
Write-Host "[5/5] Launching Device Configurator..." -ForegroundColor Yellow
Write-Host "--> Select 'Default (Output A1 - Voicemeeter)' or your target device, click OK, then reboot." -ForegroundColor Yellow
Start-Process "$eqApoDir\Configurator.exe" -Wait

# Cleanup
Remove-Item -Path $temp -Recurse -Force
Write-Host "=== Installation Complete! ===" -ForegroundColor Green