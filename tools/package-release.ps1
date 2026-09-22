$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$stage = Join-Path (Split-Path $repo -Parent) 'work\release-v1.0.0'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$windows = Join-Path $stage 'windows'
New-Item -ItemType Directory -Force -Path $windows | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'builds\windows\ClockOutAlive.exe') -Destination $windows
Copy-Item -LiteralPath (Join-Path $repo 'GODOT_NOTICES.txt') -Destination $windows
Compress-Archive -Path (Join-Path $windows '*') -DestinationPath (Join-Path $stage 'ClockOutAlive-Windows.zip') -CompressionLevel Optimal

$web = Join-Path $stage 'web'
New-Item -ItemType Directory -Force -Path $web | Out-Null
Copy-Item -Path (Join-Path $repo 'docs\*') -Destination $web -Recurse
Compress-Archive -Path (Join-Path $web '*') -DestinationPath (Join-Path $stage 'ClockOutAlive-Web.zip') -CompressionLevel Optimal

$project = Join-Path $stage 'godot'
New-Item -ItemType Directory -Force -Path $project | Out-Null
foreach ($path in @('assets','scenes','scripts','source_art','tests','tools','.gitignore','ASSET_CREDITS.md','DEVLOG.md','GODOT_NOTICES.txt','README.md','RELEASE_NOTES.md','export_presets.cfg','project.godot')) {
	$source = Join-Path $repo $path
	if (Test-Path -LiteralPath $source -PathType Container) { Copy-Item -LiteralPath $source -Destination $project -Recurse }
	else { Copy-Item -LiteralPath $source -Destination $project }
}
Compress-Archive -Path (Join-Path $project '*') -DestinationPath (Join-Path $stage 'ClockOutAlive-Godot.zip') -CompressionLevel Optimal

$hashes = foreach ($zip in Get-ChildItem -LiteralPath $stage -Filter '*.zip') {
	$hash = (certutil -hashfile $zip.FullName SHA256 | Select-Object -Skip 1 -First 1).Trim()
	'{0}  {1}' -f $hash, $zip.Name
}
$hashes | Set-Content -LiteralPath (Join-Path $stage 'SHA256SUMS.txt')
Get-ChildItem -LiteralPath $stage -File | Select-Object Name,Length
