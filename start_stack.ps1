# Start Node + Bridge reliably (auto-restart)
$ErrorActionPreference = "SilentlyContinue"

# Kill anything on 8080
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }

# Node loop
Start-Process powershell -ArgumentList @(
  '-NoExit',
  '-Command',
  'cd C:\FlutterApps\tawaqu3_final\server; while ($true) { node server.js; Start-Sleep -Seconds 1 }'
)

# Bridge loop (wait for node)
Start-Process powershell -ArgumentList @(
  '-NoExit',
  '-Command',
  'cd C:\FlutterApps\tawaqu3_final\server; Start-Sleep -Seconds 2; while ($true) { python .\tawaqu3tickbridge.py; Start-Sleep -Seconds 2 }'
)

# Bridge loop (wait for node)
Start-Process powershell -ArgumentList @(
  '-NoExit',
  '-Command',
  'cd C:\FlutterApps\tawaqu3_final\server; Start-Sleep -Seconds 2; while ($true) { python .\tawaqu3tickbridge.py; Start-Sleep -Seconds 2 }'
)
