param ([string] $DockerImage)

$dockerBuildPath = Join-Path -Path $PSScriptRoot -ChildPath docker-build
if (-Not(Test-Path -LiteralPath $dockerBuildPath)) {
    New-Item -ItemType Directory -Path $dockerBuildPath | Out-Null
}
Copy-Item -LiteralPath "$($Env:SystemRoot)\System32\vcruntime140.dll" -Destination $dockerBuildPath
Copy-Item -LiteralPath "$($Env:SystemRoot)\System32\vcomp140.dll" -Destination $dockerBuildPath
Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath setup-nodejs.ps1) -Destination $dockerBuildPath
Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath setup.ps1) -Destination $dockerBuildPath
Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "Dockerfile.$DockerImage") -Destination (Join-Path -Path $dockerBuildPath -ChildPath Dockerfile)
