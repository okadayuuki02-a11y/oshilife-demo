@echo off
cd /d "%~dp0"
echo OshiLife: image_picker を追加します...
flutter pub add image_picker
if errorlevel 1 (
  echo.
  echo image_picker の追加に失敗しました。
  echo Flutter が使えるターミナルからもう一度実行してください。
  pause
  exit /b 1
)
echo.
echo 完了しました。次は RUN_OSHILIFE.bat で起動してください。
pause
