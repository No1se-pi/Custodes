[CmdletBinding()]
param(
    [ValidateSet("eng", "ru")]
    [string]$Language = "",
    [switch]$NoPath
)

$ErrorActionPreference = "Stop"

# Windows использует то же ядро, что и Linux: PowerShell устанавливает файлы,
# а CLI запускается через Git Bash. Так правила сканера не расходятся по ОС.
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = Join-Path $env:USERPROFILE ".local\share\custodes"
$BinDir = Join-Path $env:USERPROFILE ".local\bin"
$ConfigFile = Join-Path $InstallDir ".env"
$Launcher = Join-Path $BinDir "custodes.cmd"
$BashLauncher = Join-Path $BinDir "custodes"

function Find-GitBash {
    $Candidates = @()
    $GitCommand = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($GitCommand) {
        $GitRoot = Split-Path -Parent (Split-Path -Parent $GitCommand.Source)
        $Candidates += Join-Path $GitRoot "bin\bash.exe"
    }
    $Candidates += @(
        (Join-Path $env:ProgramFiles "Git\bin\bash.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\Git\bin\bash.exe")
    )
    foreach ($Candidate in $Candidates | Select-Object -Unique) {
        if (Test-Path -LiteralPath $Candidate) { return $Candidate }
    }
    throw "Git Bash not found. Install Git for Windows and rerun install.ps1."
}

function Find-Python {
    $Python = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($Python) { return @($Python.Source) }
    $Py = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($Py) { return @($Py.Source, "-3") }
    throw "Python 3 not found. Install Python and rerun install.ps1."
}

function Copy-CustodesApplication {
    $Items = @(
        "custodes.sh", "parser.py", "README.md", "LICENSE.md", "requirements.txt",
        "lib", "locales", "custodes", "config"
    )
    New-Item -ItemType Directory -Force -Path $InstallDir, $BinDir | Out-Null
    foreach ($Item in $Items) {
        $Source = Join-Path $ScriptRoot $Item
        $Target = Join-Path $InstallDir $Item
        if (-not (Test-Path -LiteralPath $Source)) {
            throw "Distribution component is missing: $Item"
        }
        if ([IO.Path]::GetFullPath($Source) -eq [IO.Path]::GetFullPath($Target)) {
            continue
        }
        # Удаляются только известные программные файлы внутри точного InstallDir.
        # Пользовательские .env, venv и кэш Sonar при переустановке сохраняются.
        if (Test-Path -LiteralPath $Target) {
            Remove-Item -LiteralPath $Target -Recurse -Force
        }
        Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force
    }
}

function Set-CustodesLanguage([string]$SelectedLanguage) {
    if (-not (Test-Path -LiteralPath $ConfigFile)) {
        Copy-Item -LiteralPath (Join-Path $InstallDir "config\custodes.env.example") `
            -Destination $ConfigFile
    }
    $Content = Get-Content -LiteralPath $ConfigFile -Raw -Encoding UTF8
    if ($Content -match '(?m)^CUSTODES_LANG=') {
        $Content = $Content -replace '(?m)^CUSTODES_LANG=.*$', "CUSTODES_LANG=$SelectedLanguage"
    } else {
        $Content += "`r`nCUSTODES_LANG=$SelectedLanguage`r`n"
    }
    Set-Content -LiteralPath $ConfigFile -Value $Content -Encoding UTF8
}

function Install-PythonEnvironment([object[]]$PythonCommand) {
    $Executable = $PythonCommand[0]
    $PrefixArgs = @($PythonCommand | Select-Object -Skip 1)
    $VenvDir = Join-Path $InstallDir ".venv"
    & $Executable @PrefixArgs -m venv $VenvDir
    if ($LASTEXITCODE -ne 0) { throw "Cannot create Python virtual environment." }
    $VenvPython = Join-Path $VenvDir "Scripts\python.exe"
    & $VenvPython -m pip install --quiet --upgrade pip
    & $VenvPython -m pip install --quiet -r (Join-Path $InstallDir "requirements.txt")
    if ($LASTEXITCODE -ne 0) { throw "Cannot install Python dependencies." }
}

function Install-CustodesLauncher([string]$BashPath) {
    # Путь через %USERPROFILE% остаётся ASCII в самом .cmd, поэтому Windows
    # корректно раскрывает кириллицу имени пользователя уже во время запуска.
    # %* сохраняет все аргументы: custodes settings, custodes sonar scan и т.д.
    $LauncherText = "@echo off`r`nchcp 65001 >nul`r`n`"$BashPath`" `"%USERPROFILE%\.local\share\custodes\custodes.sh`" %*`r`n"
    Set-Content -LiteralPath $Launcher -Value $LauncherText -Encoding ASCII

    # Git Bash предпочитает extensionless executable. HOME раскрывается самим
    # Bash и потому также не содержит сломанной ASCII-копии Windows username.
    $BashLauncherText = @'
#!/usr/bin/env bash
"${HOME}/.local/share/custodes/custodes.sh" "$@"
'@
    Set-Content -LiteralPath $BashLauncher -Value $BashLauncherText -Encoding ASCII
}

function Add-CustodesToUserPath {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $Parts = @($UserPath -split ';' | Where-Object { $_ })
    if ($Parts -notcontains $BinDir) {
        $NewPath = (@($Parts) + $BinDir) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    }
    if (($env:Path -split ';') -notcontains $BinDir) {
        $env:Path = "$env:Path;$BinDir"
    }
}

Write-Host ""
Write-Host "CUSTODES - Windows installer" -ForegroundColor Magenta
Write-Host "Install directory: $InstallDir"

if (-not $Language) {
    $Answer = Read-Host "Language (eng/ru) [eng]"
    $Language = if ($Answer -eq "ru") { "ru" } else { "eng" }
}

$GitBash = Find-GitBash
$PythonCommand = Find-Python
Copy-CustodesApplication
Set-CustodesLanguage $Language
Install-PythonEnvironment $PythonCommand
Install-CustodesLauncher $GitBash
if (-not $NoPath) { Add-CustodesToUserPath }

Write-Host ""
Write-Host "Custodes installed successfully." -ForegroundColor Green
Write-Host "Open a new terminal, then run: custodes help"
Write-Host "In a repository run: custodes init"
