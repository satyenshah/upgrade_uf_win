@ECHO OFF

REM configure these for the desired upgrade package
set "UPGRADEFILE=splunkforwarder-8.0.3-a6754d8441bf-x64-release.msi"
set "UPGRADEVER=8.0.3"

REM store path of this bin folder
set "BINPATH=%~dp0"

REM store the parent path (i.e. the folder of this splunkapp) without keeping ".." in path which would crash msiexec
pushd
cd /d "%BINPATH%.."
set "APPPATH=%CD%"
popd

REM launch the other script as a new process
echo "Executing %BINPATH%upgrade.cmd"
echo 'start call "%BINPATH%upgrade.cmd" "%SPLUNK_HOME%" "%APPPATH%" "%UPGRADEFILE%" "%UPGRADEVER%"'
start call "%BINPATH%upgrade.cmd" "%SPLUNK_HOME%" "%APPPATH%" "%UPGRADEFILE%" "%UPGRADEVER%"
exit
