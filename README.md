# TutorsAtWork

Flutter cross-platform application for TutorsAtWork.

## Current Scope

- Login screen
- Dashboard screen
- Classrooms screen
- Firebase-ready architecture without secret keys
- Routing, state management, responsive layout, and reusable widgets

## Flutter Setup Required

Flutter is not currently available on PATH in this workspace. After installing Flutter, run:

```powershell
flutter doctor
flutter config --enable-windows-desktop
flutter create --platforms=windows,android,ios .
flutter pub get
```

Review generated platform files before committing if this repository already contains custom native code.

## Firebase Storage CORS

Web uploads and deletes to Firebase Storage require bucket CORS configuration.
Notes and homework both use the same Storage upload service, so a CORS failure
affects both features on web.

Apply the configuration in `firebase-storage-cors.json`:

```powershell
.\scripts\apply_storage_cors.ps1
```

If Google Cloud CLI is not installed locally, open Google Cloud Shell and run:

```bash
cat > firebase-storage-cors.json <<'JSON'
[
  {
    "origin": [
      "https://www.tutorsatwork.com",
      "https://ajmal-taroo.github.io",
      "http://localhost:5000",
      "http://localhost:8080",
      "http://localhost:8787",
      "http://127.0.0.1:5000",
      "http://127.0.0.1:8080",
      "http://127.0.0.1:8787"
    ],
    "method": ["GET", "HEAD", "POST", "PUT", "DELETE"],
    "responseHeader": [
      "Content-Type",
      "content-type",
      "Content-Disposition",
      "content-disposition",
      "x-goog-meta-firebaseStorageDownloadTokens",
      "x-goog-meta-firebasestoragedownloadtokens",
      "x-goog-resumable",
      "Authorization"
    ],
    "maxAgeSeconds": 3600
  }
]
JSON

gcloud storage buckets update gs://houseoftutors-f398e.firebasestorage.app --cors-file=firebase-storage-cors.json
gcloud storage buckets describe gs://houseoftutors-f398e.firebasestorage.app --format="default(cors_config)"
```
