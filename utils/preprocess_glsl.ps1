$ErrorActionPreference = 'Stop'

# Just list all your files, they will be manually concatenated, so we are avoiding
# include directives entirely (comment your #include's, or glslang.exe will fail)
$files = @(
    'C:/home/tdnew/projects/thenest/sv_tdsuite/glsl/sv_sup.glsl'
    'C:/home/tdnew/projects/thenest/sv_tdsuite/glsl/sv_lighting.glsl'
    'C:/home/tdnew/projects/thenest/glsl/final.glsl'
)

# Also you may change where result is:
$fileConcatenated = 'C:/home/docs/glslscripts/concatenated.glsl'
$filePreprocessedResult = 'C:/home/docs/glslscripts/preprocessedResult.glsl.cpp'

[System.IO.Directory]::CreateDirectory(
    [System.IO.Path]::GetDirectoryName($filePreprocessedResult)
) | Out-Null

# Print line count
$totalLinesBefore = 0
for ($i = 0; $i -lt $files.Count; $i++) {
    $fileName = [System.IO.Path]::GetFileName($files[$i])
    Write-Host "Total lines in all files before ${fileName}: $totalLinesBefore"
    $totalLinesBefore += [System.IO.File]::ReadAllLines($files[$i]).Length
}

# Concatenate all files in order.
$contents = ($files | ForEach-Object {
    [System.IO.File]::ReadAllText($_)
}) -join "`r`n"

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($fileConcatenated, $contents, $utf8NoBom)

Push-Location 'C:\home\soft\glslang\bin'
try {
    & .\glslang.exe -E -S frag $fileConcatenated |
        Out-File -LiteralPath $filePreprocessedResult -Encoding utf8

    if ($LASTEXITCODE -ne 0) {
        throw "glslang failed with exit code $LASTEXITCODE."
    }
	
	Write-Host "Successfully produced preprocessed glsl code at $filePreprocessedResult"
}
finally {
    Pop-Location
}