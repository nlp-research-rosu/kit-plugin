param(
  [string]$InstallDir = "$env:LOCALAPPDATA\IntentComputing\Kprover\bin"
)
$ErrorActionPreference = "Stop"
$BaseUrl = "https://github.com/nlp-research-rosu/kit-plugin/releases/download/v0.1.5"

$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$asset = switch ($arch) {
  "X64" { "prover-client-windows-x64.zip" }
  "Arm64" { "prover-client-windows-arm64.zip" }
  default { throw "Unsupported Windows architecture: $arch" }
}
$InstallDir = [IO.Path]::GetFullPath($InstallDir)
$target = Join-Path $InstallDir "prover-client.exe"
$marker = Join-Path $InstallDir ".prover-client.sha256"
$existing = Get-Command prover-client -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existing -and ($existing.CommandType -ne "Application" -or
    [IO.Path]::GetFullPath($existing.Source) -ne $target)) {
  throw "Another prover-client command is on PATH at $($existing.Source)"
}
if (Test-Path $target) {
  if (-not (Test-Path $marker -PathType Leaf) -or
      (Get-Content -Raw $marker).Trim() -ne (Get-FileHash $target -Algorithm SHA256).Hash) {
    throw "Refusing to replace an unrelated executable at $target"
  }
}
$work = Join-Path ([IO.Path]::GetTempPath()) ("prover-client-install-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null
try {
  $archive = Join-Path $work $asset
  Invoke-WebRequest "$BaseUrl/$asset" -OutFile $archive
  $checksumFile = Join-Path $work "checksum"
  Invoke-WebRequest "$BaseUrl/$asset.sha256" -OutFile $checksumFile
  $checksum = (Get-Content -Raw $checksumFile).Trim().Split()[0]
  if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $checksum) {
    throw "prover-client checksum mismatch"
  }
  Expand-Archive $archive -DestinationPath $work
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  Copy-Item (Join-Path $work "prover-client.exe") $target -Force
  (Get-FileHash $target -Algorithm SHA256).Hash | Set-Content -NoNewline $marker
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (($userPath -split ";") -notcontains $InstallDir) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
  }
  & $target --version
  Write-Host "Next: run prover-client health and prover-client semantics."
  Write-Host "Open a new terminal to use prover-client"
} finally {
  Remove-Item -Recurse -Force $work
}
