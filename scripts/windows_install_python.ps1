$ErrorActionPreference = "Stop"

$python_version = $Env:TEMP_PYTHON_VERSION
$filepath = "$Env:TEMP/python.exe"

echo "downloading python $python_version"
curl.exe -fsSL -o "$filepath" https://www.python.org/ftp/python/$python_version/python-$python_version-amd64.exe
if (!$?) { throw 'cmdfail' }

echo 'installing python'

Start-Process -Wait -FilePath "$filepath" `
  -ArgumentList `
    '/quiet', 'PrependPath=1', 'CompileAll=1', `
    'TargetDir=c:\python\', 'InstallAllUsers=1', 'Shortcuts=0', `
    'Include_docs=0', 'Include_tcltk=0', 'Include_tests=0'
if (!$?) { throw 'cmdfail' }

# create symbolic link for python3
New-Item -ItemType SymbolicLink -Path "C:\python" -Name "python3.exe" -Value "C:\python\python.exe"

Remove-Item "$filepath" -Force
