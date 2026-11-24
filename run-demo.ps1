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

function Invoke-DapTest {
    param([string]$Executable, [int]$Port, [string]$Request)
    $node = (Get-Command node -CommandType Application).Source
    $stdout = Join-Path $PSScriptRoot 'build\host.stdout.log'
    $stderr = Join-Path $PSScriptRoot 'build\host.stderr.log'
    $hostProcess = Start-Process -FilePath $Executable -ArgumentList @('--wait', '--port', $Port) `
        -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    try {
        $timeout = [Diagnostics.Stopwatch]::StartNew()
        do {
            if ($hostProcess.HasExited) {
                throw "Demo host exited before listening (exit code $($hostProcess.ExitCode))."
            }
            $ready = (Get-Content -LiteralPath $stdout) -contains "DAP listening on 127.0.0.1:${Port}"
            if (-not $ready) {
                Start-Sleep -Milliseconds 50
            }
        } until ($ready -or $timeout.Elapsed.TotalSeconds -ge 10)
        if (-not $ready) {
            throw 'Timed out waiting for the demo host to listen.'
        }

        & $node (Join-Path $PSScriptRoot 'test-dap.mjs') $Port $Request | ForEach-Object { Write-Host $_ }
        return $LASTEXITCODE
    } finally {
        try {
            if (-not $hostProcess.HasExited) {
                $hostProcess.Kill()
            }
            $hostProcess.WaitForExit()
        } finally {
            $hostProcess.Dispose()
        }
        Write-Host 'Demo host stopped.'
        Get-Content -LiteralPath $stdout, $stderr | ForEach-Object { Write-Host $_ }
    }
}

try {
    $buildOnly = $false
    $test = $false
    $debuggerDir = $null
    $port = 9002
    $testRequest = 'attach'
    for ($i = 0; $i -lt $args.Count; $i++) {
        switch ($args[$i]) {
            '--build-only' { $buildOnly = $true }
            '--test' { $test = $true }
            '--asdebugger-dir' {
                $i++
                if (-not $args[$i] -or $args[$i].StartsWith('--')) {
                    throw '--asdebugger-dir requires a path.'
                }
                $debuggerDir = (Resolve-Path -LiteralPath $args[$i]).ProviderPath
            }
            '--port' {
                $i++
                if (-not [int]::TryParse($args[$i], [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
                    throw '--port requires a number from 1 to 65535.'
                }
            }
            '--test-launch' {
                $test = $true
                $testRequest = 'launch'
            }
            '--help' {
                Write-Host 'Usage: run-demo.cmd [--build-only | --test | --test-launch] [--asdebugger-dir PATH] [--port N]'
                exit 0
            }
            default { throw "Unknown option $($args[$i])." }
        }
    }
    if ($buildOnly -and $test) {
        throw 'Use --build-only or a test mode.'
    }

    Set-Location -LiteralPath $PSScriptRoot
    $angelScriptReady = Test-Path -LiteralPath 'external/angelscript/sdk/angelscript/projects/cmake/CMakeLists.txt'
    $debuggerReady = Test-Path -LiteralPath 'external/asdebugger/src/core/as_debugger_host.h'
    $debuggerGitlink = (git ls-files --stage -- external/asdebugger) -match '^160000 '
    if (-not $angelScriptReady -or ($debuggerGitlink -and -not $debuggerReady -and -not $debuggerDir)) {
        Invoke-Checked git @('submodule', 'update', '--init', '--recursive')
    }

    Initialize-Compiler
    $configure = @('-S', '.', '-B', 'build', '-G', 'Ninja Multi-Config')
    if ($debuggerDir) {
        $configure += "-DASDEBUGGER_DIR=$debuggerDir"
    }
    Invoke-Checked cmake $configure
    Invoke-Checked cmake @('--build', 'build', '--config', 'Release', '--target', 'angelscript-demo', '--parallel', '4')

    $executable = Join-Path $PSScriptRoot 'build\bin\Release\angelscript-demo.exe'
    if ($buildOnly) {
        exit 0
    }
    if ($test) {
        exit (Invoke-DapTest -Executable $executable -Port $port -Request $testRequest)
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
