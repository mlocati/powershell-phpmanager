param(
    [string]
    $Tag
)
if (-not($Tag -match '^\d+\.\d+\.\d+$')) {
    Write-Host "Skipping, since '$Tag' does not represent a version"
    return
}

$ErrorActionPreference = 'Stop'

function Get-ReleaseNotes {
    param(
        [string]
        $PublishingTag
    )
    Write-Host 'Determinng release notes:'
    Write-Host '- listing git tags'
    $tags = @(& git tag --list --sort=-version:refname)
    if ($tags.Count -lt 2) {
        Write-Host '- less than 2 tags found: empty release notes'
        return ''
    }
    $publishingTagIndex = [array]::IndexOf($tags, $PublishingTag)
    if ($publishingTagIndex -lt 0) {
        throw 'Unable to find the index of the current tag!'
    }
    $previousTag = ''
    for ($tagIndex = $publishingTagIndex + 1; $tagIndex -lt $tags.Count; $tagIndex++) {
        if ($tags[$tagIndex] -match '^\d+\.\d+\.\d+$') {
            Write-Host "- calculating release notes between tag $($tags[$tagIndex]) and tag $PublishingTag"
            $previousTag = $tags[$tagIndex]
            break
        }
    }
    if ($previousTag -eq '') {
        Write-Host '- unable to find the previously published tag: empty release notes'
        return ''
    }
    $rawCommitMessages = @(& git log --format='%s' --no-merges --reverse ("$previousTag...$PublishingTag") -- .\PhpManager)
    $commitMessagesDisplay = @()
    $commitMessagesResult = @()
    foreach ($rawCommitMessage in $rawCommitMessages) {
        if (-not($rawCommitMessage -imatch '^\[minor\]')) {
            $commitMessagesDisplay += "  - $rawCommitMessage"
            $commitMessagesResult += "- $rawCommitMessage"
        }
    }
    if ($commitMessagesResult.Count -lt 1) {
        Write-Host '- no relevant commit messages found: empty release notes'
        return ''
    }
    $commitMessagesDisplay = [string]::Join("`n", $commitMessagesDisplay)
    Write-Host "- release notes:`n$commitMessagesDisplay"
    return [string]::Join("`n", $commitMessagesResult)
}

function Set-PhpManagerMetadata {
    param(
        [string]
        $Version,
        [string]
        $ReleaseNotes
    )
    Write-Host 'Configuring module metadata'
    Update-ModuleManifest -Path .\PhpManager\PhpManager.psd1 `
        -ModuleVersion $Version `
        -ReleaseNotes $ReleaseNotes `
        -Copyright "(c) 2018-$(Get-Date -Format yyyy) Michele Locati. All rights reserved."
    Write-Host '- done'
}

function Compress-PhpManager {
    Write-Host 'Creating release assets'
    $destinazionZip = .\PhpManager.zip
    Compress-Archive -Path .\PhpManager -DestinationPath $destinazionZip -Force
    Write-Host '- done'
    return $destinazionZip
}

function Publish-PhpManagerToPSGallery {
    param(
        [string]
        $Version,
        [string]
        $ReleaseNotes
    )
    Write-Host 'Publishing to PowerShell Gallery'
    Write-Host '- importing module'
    Import-Module -Force .\PhpManager
    Write-Host '- publishing'
    Publish-Module -Repository PSGallery -Path .\PhpManager -NuGetApiKey $Env:PUBLISHKEY_PG -Force | Out-Null
    Write-Host '- done'
}

function Publish-PhpManagerToGitHubReleases {
    param(
        [string]
        $Tag,
        [string]
        $ReleaseNotes,
        [string]
        $ReleaseZip
    )
    Write-Host 'Publishing to GitHub Releases'
    Write-Host '- preparing request data'
    $deleteDraft = $true
    Write-Host '- creating draft release'
    $release = Invoke-RestMethod `
        -Method 'POST' `
        -Uri 'https://api.github.com/repos/mlocati/powershell-phpmanager/releases' `
        -UserAgent 'mlocati' `
        -Headers @{
            'Accept'        = 'application/vnd.github.v3+json';
            'Authorization' = "token $Env:PUBLISHKEY_GH";
        } `
        -Body (ConvertTo-Json -InputObject @{
            'tag_name' = $Tag;
            'name'     = "v${Tag}";
            'body'     = $ReleaseNotes;
            'draft'    = $true;
        })
    try {
        Write-Host '- adding assets'
        Invoke-RestMethod `
            -Method 'POST' `
            -Uri "https://uploads.github.com/repos/mlocati/powershell-phpmanager/releases/$($release.id)/assets?name=PhpManager.zip" `
            -UserAgent 'mlocati' `
            -Headers @{
                'Accept'        = 'application/vnd.github.v3+json';
                'Authorization' = "token $Env:PUBLISHKEY_GH";
                'Content-Type'  = 'application/zip'
            } `
            -InFile $ReleaseZip `
            | Out-Null
        Write-Host '- marking the release as non draft'
        Invoke-RestMethod `
            -Method 'PATCH' `
            -Uri "https://api.github.com/repos/mlocati/powershell-phpmanager/releases/$($release.id)" `
            -UserAgent 'mlocati' `
            -Headers @{
                'Accept'        = 'application/vnd.github.v3+json';
                'Authorization' = "token $Env:PUBLISHKEY_GH";
            } `
            -Body (ConvertTo-Json -InputObject @{
                'draft' = $false;
            }) `
            | Out-Null
        $deleteDraft = $false
    }
    finally {
        if ($deleteDraft) {
            try {
                Invoke-RestMethod `
                    -Method 'DELETE' `
                    -Uri "https://api.github.com/repos/mlocati/powershell-phpmanager/releases/$($release.id)" `
                    -UserAgent 'mlocati' `
                    -Headers @{
                        'Accept'        = 'application/vnd.github.v3+json';
                        'Authorization' = "token $Env:PUBLISHKEY_GH";
                    } `
                    | Out-Null
            }
            catch {
            }
        }
    }
    Write-Host '- done'
}

Write-Host "Publishing version v$Tag"
$releaseNotes = Get-ReleaseNotes -PublishingTag $Tag
Set-PhpManagerMetadata -Version $Tag -ReleaseNotes $releaseNotes
$releaseZip = Compress-PhpManager
Publish-PhpManagerToPSGallery -Version $Tag -ReleaseNotes $releaseNotes
Publish-PhpManagerToGitHubReleases -Tag $Tag -ReleaseNotes $releaseNotes -ReleaseZip $releaseZip
