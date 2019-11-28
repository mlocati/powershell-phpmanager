$dockerBuildPath = Join-Path -Path $PSScriptRoot -ChildPath docker-build
if (-Not(Test-Path -LiteralPath $dockerBuildPath)) {
    New-Item -ItemType Directory -Path $dockerBuildPath | Out-Null
}
$me = Get-Item -LiteralPath $PSCommandPath
try {
    Copy-Item -LiteralPath "$($Env:SystemRoot)\System32\vcruntime140.dll" -Destination $dockerBuildPath
    Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath setup-nodejs.ps1) -Destination $dockerBuildPath
    Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath setup.ps1) -Destination $dockerBuildPath
    Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath $me.BaseName) -Destination (Join-Path -Path $dockerBuildPath -ChildPath Dockerfile)
    docker build --rm --force-rm --tag phpmanager/test $dockerBuildPath
} finally {
    try {
        Remove-Item -LiteralPath $dockerBuildPath -Recurse
    } catch {
    }
}
