@echo off
chcp 65001 >nul
cd /d %~dp0
flutter pub get
flutter build web --release
pause
