param([Parameter(Mandatory=$true)][string]$Godot)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

function Invoke-Godot([string[]]$GameArgs) {
    $output = & $Godot @GameArgs 2>&1
    if ($LASTEXITCODE -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:')) {
        $output | Write-Output
        throw 'Godot validation or export failed.'
    }
    $output | Select-Object -Last 2 | Write-Output
}

Invoke-Godot @('--headless', '--path', '.', '--editor', '--import')
foreach ($suite in @('test_first_five', 'test_microgames_six_ten', 'test_shift', 'test_full_shift_inputs', 'test_ui_layout')) {
    Invoke-Godot @('--headless', '--path', '.', '--script', "tests/$suite.gd")
}
Invoke-Godot @('--headless', '--path', '.', '--script', 'tools/write_engine_notices.gd')
New-Item -ItemType Directory -Force -Path 'builds/windows', 'docs' | Out-Null
Invoke-Godot @('--headless', '--path', '.', '--export-release', 'Web', 'docs/index.html')
Invoke-Godot @('--headless', '--path', '.', '--export-release', 'Windows Desktop', 'builds/windows/ClockOutAlive.exe')
$webEntry = Join-Path (Get-Location) 'docs/index.html'
[IO.File]::WriteAllText($webEntry, [IO.File]::ReadAllText($webEntry).TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath 'GODOT_NOTICES.txt' -Destination 'docs/GODOT_NOTICES.txt'
Write-Output 'Web and Windows release exports complete.'
