@echo off
cd /d "%~dp0"

set PORT=7357
set LOCAL_IP=

for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$cfg = Get-NetIPConfiguration ^| Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } ^| Select-Object -First 1; if ($cfg) { $cfg.IPv4Address.IPAddress }"`) do set LOCAL_IP=%%I

echo ==========================================
echo OshiLife Web Test
echo ==========================================
echo.
echo PC:
echo   http://localhost:%PORT%
echo.

if defined LOCAL_IP (
  echo Smartphone ^(same Wi-Fi^):
  echo   http://%LOCAL_IP%:%PORT%
) else (
  echo Smartphone URL could not be detected automatically.
  echo Run ipconfig and use:
  echo   http://YOUR_IPV4_ADDRESS:%PORT%
)

echo.
echo Keep this window open while testing.
echo Press q to stop Flutter.
echo.
echo If Windows Firewall asks for permission,
echo allow access on Private networks.
echo.

start "" powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 3; Start-Process 'http://localhost:%PORT%'"

flutter run -d web-server --web-hostname 0.0.0.0 --web-port %PORT%

echo.
echo OshiLife stopped.
pause
