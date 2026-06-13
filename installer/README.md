# TutorsAtWork Windows Installer

Run from PowerShell:

```powershell
.\installer\build_installer.ps1
```

The script builds the Windows x64 release and creates:

`installer\output\TutorsAtWork-Setup-1.0.0-x64.exe`

The installer supports Windows 10 version 1809 or newer and bundles:

- Microsoft Visual C++ x64 Runtime
- Microsoft Edge WebView2 Evergreen Bootstrapper

Update `AppVersion` in `TutorsAtWork.iss` when the app version changes.
