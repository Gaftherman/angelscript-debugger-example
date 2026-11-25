$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed with exit code $LASTEXITCODE."
    }
}

function Initialize-Compiler {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) {
        throw 'Install Visual Studio or Build Tools with the Desktop development with C++ workload.'
    }
    $installation = & $vswhere -latest -products '*' -version '[17.0,)' `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $installation) {
        throw 'Visual Studio 2022 or later with the MSVC x64 tools is required.'
    }

    $vcvars = Join-Path $installation 'VC\Auxiliary\Build\vcvars64.bat'
    $env:Path = "$(Split-Path -Parent $vswhere);$env:Path"
    $environment = & $env:ComSpec /d /c "call `"$vcvars`" >nul && set"
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not initialize the MSVC x64 environment with vcvars64.bat.'
    }
    foreach ($entry in $environment) {
        if ($entry -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process')
        }
    }
    $tools = Join-Path $installation 'Common7\IDE\CommonExtensions\Microsoft\CMake'
    $env:Path += ";$tools\CMake\bin;$tools\Ninja"
}

try {
    $buildOnly = $false
    $port = 9002
    for ($i = 0; $i -lt $args.Count; $i++) {
        switch ($args[$i]) {
            '--build-only' { $buildOnly = $true }
            '--port' {
                $i++
                if (-not [int]::TryParse($args[$i], [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
                    throw '--port requires a number from 1 to 65535.'
                }
            }
            '--help' {
                Write-Host 'Usage: run-demo.cmd [--build-only] [--port N]'
                exit 0
            }
            default { throw "Unknown option $($args[$i])." }
        }
    }

    Set-Location -LiteralPath $PSScriptRoot
    $angelScriptReady = Test-Path -LiteralPath 'external/angelscript/sdk/angelscript/projects/cmake/CMakeLists.txt'
    if (-not $angelScriptReady) {
        Invoke-Checked git @('submodule', 'update', '--init', '--recursive')
    }

    Initialize-Compiler
    Invoke-Checked cmake @('-S', '.', '-B', 'build', '-G', 'Ninja Multi-Config')
    Invoke-Checked cmake @('--build', 'build', '--config', 'Release', '--target', 'angelscript-demo', '--parallel', '4')

    $executable = Join-Path $PSScriptRoot 'build\bin\Release\angelscript-demo.exe'
    if ($buildOnly) {
        exit 0
    }

    Write-Host 'In VS Code, set a breakpoint on a // BP line, select Attach to AngelScript Demo, and press F5.'
    if ($port -ne 9002) {
        Write-Host "Set the attach configuration's port to $port first."
    }
    & $executable --wait --port $port
    exit $LASTEXITCODE
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
