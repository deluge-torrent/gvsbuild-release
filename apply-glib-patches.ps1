# Apply glib patches to gvsbuild
# Parses glib.py to check for numbering conflicts before copying patches
#
# Usage:
#   apply-glib-patches.ps1 -gvsbuildRoot C:\path\to\gvsbuild

param(
    [Parameter(Mandatory=$true)]
    [string]$gvsbuildRoot
)

$ErrorActionPreference = "Stop"

# Paths
$patchSourceDir = "$PSScriptRoot\gvsbuild\patches\glib"
$glibPy = "$gvsbuildRoot\gvsbuild\projects\glib.py"
$patchDestDir = "$gvsbuildRoot\gvsbuild\patches\glib"

Write-Host "Applying glib patches to gvsbuild..." -ForegroundColor Cyan
Write-Host ""

# Validate source directory exists
if (-not (Test-Path $patchSourceDir)) {
    Write-Host "ERROR: Patch directory not found: $patchSourceDir" -ForegroundColor Red
    exit 1
}

# Get patches to apply
$patchesToApply = Get-ChildItem $patchSourceDir -Filter "*.patch" | Sort-Object Name

if ($patchesToApply.Count -eq 0) {
    Write-Host "No patches found in $patchSourceDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($patchesToApply.Count) patch(es) to apply:" -ForegroundColor Green
foreach ($patch in $patchesToApply) {
    Write-Host "  - $($patch.Name)"
}
Write-Host ""

# Parse glib.py to find existing patches
if (-not (Test-Path $glibPy)) {
    Write-Host "ERROR: glib.py not found: $glibPy" -ForegroundColor Red
    Write-Host "Ensure gvsbuild is checked out at: $gvsbuildRoot" -ForegroundColor Yellow
    exit 1
}

Write-Host "Checking for conflicts in glib.py..." -ForegroundColor Cyan

$glibPyContent = Get-Content $glibPy -Raw
$existingPatches = [regex]::Matches($glibPyContent, '"(\d{3}.*?\.patch)"') | ForEach-Object { $_.Groups[1].Value }

Write-Host "Found $($existingPatches.Count) existing patch(es) in glib.py" -ForegroundColor Green
Write-Host ""

# Check for conflicts
$conflicts = @()
foreach ($patch in $patchesToApply) {
    # Extract patch number (e.g., "003" from "003-fix-win-socket-errors.patch")
    if ($patch.Name -match '^(\d{3})') {
        $patchNumber = $matches[1]

        # Check if this number exists in glib.py
        foreach ($existing in $existingPatches) {
            if ($existing -match "^$patchNumber") {
                $conflicts += "Patch number conflict: $($patch.Name) conflicts with existing $existing"
            }
        }
    }
}

if ($conflicts.Count -gt 0) {
    Write-Host "ERROR: Patch numbering conflicts detected!" -ForegroundColor Red
    Write-Host ""
    foreach ($conflict in $conflicts) {
        Write-Host "  [X] $conflict" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please renumber patches to avoid conflicts." -ForegroundColor Yellow
    exit 1
}

Write-Host "No conflicts detected" -ForegroundColor Green
Write-Host ""

# Copy patches
Write-Host "Copying patches to $patchDestDir..." -ForegroundColor Cyan

if (-not (Test-Path $patchDestDir)) {
    New-Item -ItemType Directory -Path $patchDestDir -Force | Out-Null
}

foreach ($patch in $patchesToApply) {
    $destPath = Join-Path $patchDestDir $patch.Name
    Copy-Item $patch.FullName $destPath -Force
    Write-Host "  [OK] Copied $($patch.Name)" -ForegroundColor Green
}

Write-Host ""

# Register patches in glib.py
Write-Host "Registering patches in glib.py..." -ForegroundColor Cyan

$glibPyContent = Get-Content $glibPy -Raw

foreach ($patch in $patchesToApply) {
    # Check if already registered
    if ($glibPyContent -match [regex]::Escape("`"$($patch.Name)`"")) {
        Write-Host "  [SKIP] $($patch.Name) already registered" -ForegroundColor Yellow
        continue
    }

    # Find last patch entry to insert after
    $lastPatch = $existingPatches[-1]
    $pattern = [regex]::Escape("`"$lastPatch`",")
    $replacement = "`"$lastPatch`",`n                `"$($patch.Name)`","

    # Replace all occurrences (for both GLibBase and GLib classes)
    $glibPyContent = $glibPyContent -replace $pattern, $replacement

    Write-Host "  [OK] Registered $($patch.Name)" -ForegroundColor Green
}

Set-Content $glibPy $glibPyContent -NoNewline

Write-Host ""
Write-Host "SUCCESS: All patches applied and registered" -ForegroundColor Green
Write-Host ""
exit 0
