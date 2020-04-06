REM ECHO OFF
REM get splunk path from argument
set SPLUNK_HOME=%~1

REM get app path from argument
set SPLUNK_APP=%~2

REM get msi filename from argument
set SPLUNK_FILE=%~3

REM get desired version from argument
set SPLUNK_VER=%~4

REM get filesize of the MSIEXEC log and MSI file to know if this upgrade was previously attempted
for %%I in ("%SPLUNK_APP%\static\splunkupgrade.log") do set historysize=%%~zI
for %%I in ("%SPLUNK_APP%\static\splunkupgrade.txt") do set commentsize=%%~zI
for %%I in ("%SPLUNK_APP%\static\%SPLUNK_FILE%") do set msisize=%%~zI

REM abort if the upgrade was previously attempted
IF %historysize% GTR 0 exit
IF %commentsize% GTR 0 exit
IF %msisize% EQU 0 exit

REM get Windows version from ver command
for /f "tokens=4-5 delims=. " %%i in ('ver') do set WIN_VERSION=%%i.%%j

REM get installed version of Splunk grepped from filesystem
for /F "delims=" %%a in ('%WINDIR%\System32\findstr.exe /c:"VERSION=" "%SPLUNK_HOME%\etc\splunk.version"') do set "CURRENT_VER=%%a"

REM abort if new/newer UF version is already installed; kill MSI file
IF "%CURRENT_VER%" GEQ "VERSION=%SPLUNK_VER%" TYPE NUL > "%SPLUNK_APP%\static\%SPLUNK_FILE%"
IF "%CURRENT_VER%" GEQ "VERSION=%SPLUNK_VER%" exit

REM abort if not 2012 windows or newer; kill MSI file
IF %WIN_VERSION% LSS 6.2 TYPE NUL > "%SPLUNK_APP%\static\%SPLUNK_FILE%"
IF %WIN_VERSION% LSS 6.2 exit

REM abort if not x64 windows; kill MSI file
IF NOT "%PROCESSOR_ARCHITECTURE%" == "AMD64" TYPE NUL > "%SPLUNK_APP%\static\%SPLUNK_FILE%"
IF NOT "%PROCESSOR_ARCHITECTURE%" == "AMD64" exit

echo "Upgrading Splunk from %CURRENT_VER% to %SPLUNK_VER%, installing %SPLUNK_FILE%" >> "%SPLUNK_APP%\static\splunkupgrade.txt"
%WINDIR%\System32\net.exe stop SplunkForwarder

%WINDIR%\System32\sc.exe queryex "SplunkForwarder" | %WINDIR%\System32\find.exe "STATE" | %WINDIR%\System32\find.exe "STOPPED">Nul||(
 echo "Warning: SplunkForwarder service did not stop in timely manner.  Waiting 2 minutes." >> "%SPLUNK_APP%\static\splunkupgrade.txt"
 %WINDIR%\System32\timeout.exe 120
)

%WINDIR%\System32\sc.exe queryex "SplunkForwarder" | %WINDIR%\System32\find.exe "STATE" | %WINDIR%\System32\find.exe "STOPPED">Nul&&(
 echo 'msiexec.exe /L*V "%SPLUNK_APP%\static\splunkupgrade.log" /i "%SPLUNK_APP%\static\%SPLUNK_FILE%" AGREETOLICENSE=Yes GENRANDOMPASSWORD=1 /quiet /norestart' >> "%SPLUNK_APP%\static\splunkupgrade.txt"
 %WINDIR%\System32\msiexec.exe /L*V "%SPLUNK_APP%\static\splunkupgrade.log" /i "%SPLUNK_APP%\static\%SPLUNK_FILE%" AGREETOLICENSE=Yes GENRANDOMPASSWORD=1 /quiet /norestart
 TYPE NUL > "%SPLUNK_APP%\static\%SPLUNK_FILE%"
)||(
 echo "Error: SplunkForwarder service did not stop in timely manner.  Will not attempt upgrade." >> "%SPLUNK_APP%\static\splunkupgrade.txt"
)
%WINDIR%\System32\timeout.exe 15
%WINDIR%\System32\net.exe start SplunkForwarder

exit
