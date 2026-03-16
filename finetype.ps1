#
# FineType installer for Windows
# https://meridian.online
#
# Detects architecture, downloads the correct pre-built binary from
# GitHub Releases, verifies its SHA256 checksum, and installs it to a
# versioned directory with a latest directory junction.
#
# Usage:
#   irm https://install.meridian.online/finetype/win | iex
#   irm https://install.meridian.online/finetype/win | iex -Args 'v0.6.12'
#

$ErrorActionPreference = 'Stop'

$Repo = "meridian-online/finetype"
$InstallRoot = Join-Path $env:LOCALAPPDATA "finetype\cli"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Info($msg)  { Write-Host "  $msg" }
function Warn($msg)  { Write-Host "  warning: $msg" -ForegroundColor Yellow }
function Abort($msg) { Write-Host "  error: $msg" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------

function Show-Banner {
    Write-Host ""
    Write-Host "           ☼☼☼☼               "
    Write-Host "        ☼☼☼☼☼☼☼☼              "
    Write-Host "                ☼☼☼☼☼☼☼☼☼☼    "
    Write-Host "                  ☼☼☼☼☼☼☼☼☼☼  "
    Write-Host "   ☼☼☼☼☼☼☼☼☼☼☼☼               "
    Write-Host "  ☼☼☼☼☼☼☼☼☼☼☼☼☼☼              "
    Write-Host "                ☼☼☼☼☼☼☼☼☼☼☼☼☼☼"
    Write-Host "                 ☼☼☼☼☼☼☼☼☼☼☼☼ "
    Write-Host "     ☼☼☼☼☼☼☼☼☼☼               "
    Write-Host "      ☼☼☼☼☼☼☼☼☼☼              "
    Write-Host "                ☼☼☼☼☼☼☼☼      "
    Write-Host "                 ☼☼☼☼         "
    Write-Host ""
    Write-Host "            MERIDIAN"
    Write-Host ""
    Write-Host "  FineType installer"
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Detect platform
# ---------------------------------------------------------------------------

function Detect-Target {
    $arch = $null

    # Try .NET RuntimeInformation first (PowerShell 6+)
    try {
        $osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
        switch ($osArch) {
            "X64"  { $arch = "x86_64" }
            "Arm64" { $arch = "aarch64" }
            default { Abort "unsupported architecture: $osArch" }
        }
    } catch {
        # Fall back to environment variable (Windows PowerShell 5.1)
        $procArch = $env:PROCESSOR_ARCHITECTURE
        switch ($procArch) {
            "AMD64" { $arch = "x86_64" }
            "ARM64" { $arch = "aarch64" }
            default { Abort "unsupported architecture: $procArch" }
        }
    }

    return "${arch}-pc-windows-msvc"
}

# ---------------------------------------------------------------------------
# Resolve version
# ---------------------------------------------------------------------------

function Resolve-Version($requested) {
    if ($requested) {
        if (-not $requested.StartsWith("v")) {
            $requested = "v$requested"
        }
        return $requested
    }

    # Query GitHub API for the latest release tag
    $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "finetype-installer" }
        $tag = $response.tag_name
    } catch {
        Abort "could not determine latest version from GitHub API: $_"
    }

    if (-not $tag) {
        Abort "could not determine latest version from GitHub API"
    }

    return $tag
}

# ---------------------------------------------------------------------------
# Download and verify
# ---------------------------------------------------------------------------

function Download-AndVerify($version, $target, $tmpDir) {
    $archive = "finetype-${version}-${target}.zip"
    $checksumFile = "${archive}.sha256"
    $baseUrl = "https://github.com/$Repo/releases/download/$version"

    $archivePath = Join-Path $tmpDir $archive
    $checksumPath = Join-Path $tmpDir $checksumFile

    Info "downloading ${archive}..."
    try {
        Invoke-WebRequest -Uri "${baseUrl}/${archive}" -OutFile $archivePath -UseBasicParsing
    } catch {
        Abort "failed to download ${archive} -- does release ${version} exist?"
    }

    Info "downloading checksum..."
    try {
        Invoke-WebRequest -Uri "${baseUrl}/${checksumFile}" -OutFile $checksumPath -UseBasicParsing
    } catch {
        Abort "failed to download checksum file"
    }

    # Verify SHA256
    Info "verifying checksum..."
    $expected = (Get-Content $checksumPath -Raw).Trim().Split(" ")[0].ToLower()
    $actual = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash.ToLower()

    if ($expected -ne $actual) {
        Abort "checksum mismatch!`n  expected: ${expected}`n  actual:   ${actual}"
    }

    Info "checksum verified."
    return $archivePath
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

function Install-Binary($version, $archivePath) {
    $versionDir = Join-Path $InstallRoot $version
    $latestDir = Join-Path $InstallRoot "latest"

    # Create versioned directory
    if (-not (Test-Path $versionDir)) {
        New-Item -ItemType Directory -Path $versionDir -Force | Out-Null
    }

    # Extract zip
    Info "extracting to ${versionDir}..."
    try {
        Expand-Archive -Path $archivePath -DestinationPath $versionDir -Force
    } catch {
        Abort "failed to extract archive: $_"
    }

    # Update latest directory junction
    if (Test-Path $latestDir) {
        # Remove existing junction or directory
        (Get-Item $latestDir).Delete()
    }
    New-Item -ItemType Junction -Path $latestDir -Target $versionDir | Out-Null
    Info "updated ${latestDir} -> ${versionDir}"
}

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------

function Update-Path {
    $latestDir = Join-Path $InstallRoot "latest"
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)

    # Check if already on PATH
    $pathEntries = $userPath -split ";"
    $alreadyOnPath = $pathEntries | Where-Object { $_.TrimEnd("\") -eq $latestDir.TrimEnd("\") }

    if ($alreadyOnPath) {
        return
    }

    # Also check if finetype.exe is reachable in current session
    $existing = Get-Command finetype -ErrorAction SilentlyContinue
    if ($existing) {
        return
    }

    # Add to User PATH
    $newPath = "${userPath};${latestDir}"
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)

    Write-Host ""
    Info "added ${latestDir} to your User PATH."
    Warn "restart your terminal for PATH changes to take effect."
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Show-Banner

# Detect platform
$target = Detect-Target
Info "detected platform: $target"

# Resolve version
$version = Resolve-Version ($args[0])
Info "version: $version"
Write-Host ""

# Create temp directory
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "finetype-install-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

try {
    # Download, verify, install
    $archivePath = Download-AndVerify $version $target $tmpDir
    Install-Binary $version $archivePath

    Write-Host ""
    Write-Host "  FineType $version installed successfully!"
    Write-Host ""

    # Verify the binary runs
    $installedBin = Join-Path $InstallRoot "$version\finetype.exe"
    if (Test-Path $installedBin) {
        try {
            $versionOutput = & $installedBin --version 2>$null
            if ($versionOutput) {
                Info $versionOutput
            }
        } catch { }
    }

    Update-Path
} finally {
    # Clean up temp directory
    if (Test-Path $tmpDir) {
        Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
