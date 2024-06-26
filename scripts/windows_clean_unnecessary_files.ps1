# Do not error out if files do not exist
$ErrorActionPreference = "SilentlyContinue"

cd c:\
Remove-Item C:\t -Force -Recurse
Remove-Item -Force -Recurse ${Env:TEMP}\*
Remove-Item -Force -Recurse "${Env:ProgramData}\Package Cache"
