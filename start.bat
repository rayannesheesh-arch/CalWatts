@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT=%~dp0"

echo.
echo  CalWatt local launcher
echo  ---------------------

where node >nul 2>nul
if errorlevel 1 (
  echo ERROR: Node.js is not installed or is not on PATH.
  echo Install Node.js 20.19+ and run start.bat again.
  goto :fail
)

where npm >nul 2>nul
if errorlevel 1 (
  echo ERROR: npm is not installed or is not on PATH.
  goto :fail
)

if not exist "%ROOT%backend\.env" (
  copy "%ROOT%backend\.env.example" "%ROOT%backend\.env" >nul
  echo Created backend\.env from the example.
  echo.
  echo One-time setup required before starting:
  echo   1. Create the MySQL calwatts database and calwatts_app user.
  echo   2. Edit backend\.env with the database password and unique secrets.
  echo   3. Replace the example admin and sample-user passwords.
  echo   See the Windows setup section in README.md for the SQL commands.
  goto :fail
)

findstr /C:"replace-this-with-a-long-random-secret" "%ROOT%backend\.env" >nul
if not errorlevel 1 goto :env_incomplete
findstr /C:"replace-with-a-local-database-password" "%ROOT%backend\.env" >nul
if not errorlevel 1 goto :env_incomplete
findstr /C:"DevelopmentAdmin-ChangeMe-2026" "%ROOT%backend\.env" >nul
if not errorlevel 1 goto :env_incomplete
findstr /C:"DevelopmentUser-ChangeMe-2026" "%ROOT%backend\.env" >nul
if not errorlevel 1 goto :env_incomplete

echo Checking MySQL service...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = Get-Service -Name 'MySQL80' -ErrorAction SilentlyContinue; if (-not $s) { $s = Get-Service -Name 'MySQL' -ErrorAction SilentlyContinue }; if (-not $s) { Write-Error 'No MySQL80 or MySQL Windows service was found.'; exit 1 }; if ($s.Status -ne 'Running') { try { Start-Service -Name $s.Name -ErrorAction Stop } catch { Write-Error ('Could not start MySQL service: ' + $_.Exception.Message); exit 1 } }; Write-Host ('MySQL service is ' + (Get-Service -Name $s.Name).Status + '.')"
if errorlevel 1 (
  echo ERROR: Could not start MySQL. Check the service and your Windows permissions.
  goto :fail
)

if not exist "%ROOT%backend\node_modules" (
  echo Installing backend packages...
  call npm ci --prefix "%ROOT%backend" --no-audit --no-fund
  if errorlevel 1 goto :install_failed
)
if not exist "%ROOT%frontend\node_modules" (
  echo Installing frontend packages...
  call npm ci --prefix "%ROOT%frontend" --no-audit --no-fund
  if errorlevel 1 goto :install_failed
)

echo Applying database migrations...
call npm --prefix "%ROOT%backend" run migrate
if errorlevel 1 (
  echo.
  echo ERROR: Database setup failed. Confirm MySQL is running and backend\.env
  echo matches the database and calwatts_app account you created.
  echo See README.md for the one-time MySQL setup commands.
  goto :fail
)

echo Preparing local development accounts and sample appliances...
call npm --prefix "%ROOT%backend" run seed:dev
if errorlevel 1 (
  echo ERROR: Development seed failed. Check backend\.env account emails and passwords.
  goto :fail
)

echo Starting the API and web app in separate terminal windows...
start "CalWatt API" /D "%ROOT%backend" cmd /k "npm run dev"

echo Waiting for the API health check...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ready = $false; for ($i = 0; $i -lt 30; $i++) { try { $r = Invoke-RestMethod 'http://127.0.0.1:4000/api/health' -TimeoutSec 2; if ($r.status -eq 'ok') { $ready = $true; break } } catch {}; Start-Sleep -Seconds 1 }; if (-not $ready) { Write-Error 'The API did not become ready. Check the CalWatt API terminal.'; exit 1 }; Write-Host 'API is ready.'"
if errorlevel 1 goto :api_failed

set "ADB="
if defined ANDROID_SDK_ROOT if exist "%ANDROID_SDK_ROOT%\platform-tools\adb.exe" set "ADB=%ANDROID_SDK_ROOT%\platform-tools\adb.exe"
if not defined ADB if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "ADB=%ANDROID_HOME%\platform-tools\adb.exe"
if not defined ADB if defined LOCALAPPDATA if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not defined ADB for /f "delims=" %%A in ('where adb 2^>nul') do if not defined ADB set "ADB=%%A"
if not defined ADB (
  echo Android SDK platform-tools not found; skipping emulator port forwarding.
) else (
  "%ADB%" reverse tcp:4000 tcp:4000 >nul 2>nul
  if errorlevel 1 (
    echo No Android device is connected; run adb reverse tcp:4000 tcp:4000 after starting an emulator.
  ) else (
    echo Android emulator API forwarding is ready.
    for /f "tokens=1,2" %%D in ('"%ADB%" devices ^| findstr /R "^emulator-[0-9][0-9]*[ ]*device"') do set "ANDROID_DEVICE=%%D"
    if defined ANDROID_DEVICE (
      where flutter >nul 2>nul
      if errorlevel 1 (
        echo Flutter is not on PATH; run flutter run -d !ANDROID_DEVICE! to launch mobile manually.
      ) else (
        echo Starting CalWatt on !ANDROID_DEVICE!...
        start "CalWatt Mobile" /D "%ROOT%" cmd /k "flutter run -d !ANDROID_DEVICE!"
      )
    )
  )
)

start "CalWatt Web" /D "%ROOT%frontend" cmd /k "npm run dev"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ready = $false; for ($i = 0; $i -lt 20; $i++) { try { $r = Invoke-WebRequest 'http://127.0.0.1:5173' -TimeoutSec 2; if ($r.StatusCode -eq 200) { $ready = $true; break } } catch {}; Start-Sleep -Seconds 1 }; if (-not $ready) { Write-Error 'The web app did not become ready. Check the CalWatt Web terminal.'; exit 1 }; Write-Host 'Web app is ready.'"
if errorlevel 1 goto :web_failed

echo.
echo CalWatt is running at http://127.0.0.1:5173
echo Keep both CalWatt terminal windows open while using the app.
start "" "http://127.0.0.1:5173"
echo.
pause
exit /b 0

:env_incomplete
echo.
echo ERROR: backend\.env still contains example credentials.
echo Set a unique SESSION_SECRET, DB_PASSWORD, ADMIN_PASSWORD, and
echo SAMPLE_USER_PASSWORD before running the application.
goto :fail

:install_failed
echo ERROR: npm could not install dependencies. Check the output above.
goto :fail

:api_failed
echo The API failed its health check. The API terminal has been left open for details.
goto :fail

:web_failed
echo The frontend failed to start. Check the CalWatt Web terminal.
goto :fail

:fail
echo.
pause
exit /b 1
