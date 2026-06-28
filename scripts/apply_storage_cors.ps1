$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$corsFile = Join-Path $projectRoot 'firebase-storage-cors.json'
$bucket = 'gs://houseoftutors-f398e.firebasestorage.app'

if (-not (Test-Path -LiteralPath $corsFile)) {
  throw "CORS file not found: $corsFile"
}

$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
if ($gcloud) {
  & $gcloud.Source storage buckets update $bucket --cors-file=$corsFile
  & $gcloud.Source storage buckets describe $bucket --format='default(cors)'
  return
}

$gsutil = Get-Command gsutil -ErrorAction SilentlyContinue
if ($gsutil) {
  & $gsutil.Source cors set $corsFile $bucket
  & $gsutil.Source cors get $bucket
  return
}

throw @"
Neither gcloud nor gsutil is available on PATH.

Install Google Cloud CLI or open Google Cloud Shell, then run:

gcloud storage buckets update $bucket --cors-file=$corsFile
gcloud storage buckets describe $bucket --format="default(cors)"
"@
