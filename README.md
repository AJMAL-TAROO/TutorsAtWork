# TAW App

New Flutter cross-platform application for House of Tutors.

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
