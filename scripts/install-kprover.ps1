param(
  [string]$InstallDir = "$env:LOCALAPPDATA\IntentComputing\Kprover\bin"
)
$ErrorActionPreference = "Stop"
$BaseUrl = "https://github.com/nlp-research-rosu/kit-plugin/releases/download/v0.1.0"

$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$asset = switch ($arch) {
  "X64" { "kprover-windows-x64.zip" }
  "Arm64" { "kprover-windows-arm64.zip" }
  default { throw "Unsupported Windows architecture: $arch" }
}
$work = Join-Path ([IO.Path]::GetTempPath()) ("kprover-install-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null
try {
  $archive = Join-Path $work $asset
  Invoke-WebRequest "$BaseUrl/$asset" -OutFile $archive
  $checksumFile = Join-Path $work "checksum"
  Invoke-WebRequest "$BaseUrl/$asset.sha256" -OutFile $checksumFile
  $checksum = (Get-Content -Raw $checksumFile).Trim().Split()[0]
  if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $checksum) {
    throw "kprover checksum mismatch"
  }
  Expand-Archive $archive -DestinationPath $work
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  Copy-Item (Join-Path $work "kprover.exe") (Join-Path $InstallDir "kprover.exe") -Force
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (($userPath -split ";") -notcontains $InstallDir) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
  }
  & (Join-Path $InstallDir "kprover.exe") --version
  Write-Host "Next: run kprover health and kprover semantics."
  Write-Host "Open a new terminal to use kprover"
} finally {
  Remove-Item -Recurse -Force $work
}
