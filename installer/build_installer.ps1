$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$innoCompiler = Join-Path $PSScriptRoot 'tools\InnoSetup\ISCC.exe'
$innoInstaller = Join-Path $PSScriptRoot 'tools\innosetup-6.7.3.exe'
$webViewInstaller = Join-Path $PSScriptRoot 'prerequisites\MicrosoftEdgeWebView2Setup.exe'
$vcRuntimeInstaller = Join-Path $PSScriptRoot 'prerequisites\vc_redist.x64.exe'

if (-not (Test-Path -LiteralPath $webViewInstaller)) {
  Invoke-WebRequest `
    -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' `
    -OutFile $webViewInstaller
}

if (-not (Test-Path -LiteralPath $vcRuntimeInstaller)) {
  Invoke-WebRequest `
    -Uri 'https://aka.ms/vc14/vc_redist.x64.exe' `
    -OutFile $vcRuntimeInstaller
}

if (-not (Test-Path -LiteralPath $innoCompiler)) {
  if (-not (Test-Path -LiteralPath $innoInstaller)) {
    Invoke-WebRequest `
      -Uri 'https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe' `
      -OutFile $innoInstaller
  }

  $innoDirectory = Join-Path $PSScriptRoot 'tools\InnoSetup'
  Start-Process `
    -FilePath $innoInstaller `
    -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/DIR=`"$innoDirectory`"" `
    -Wait
}

Push-Location $projectRoot
try {
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter Windows release build failed with exit code $LASTEXITCODE."
  }

  & $innoCompiler (Join-Path $PSScriptRoot 'TutorsAtWork.iss')
  if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}
