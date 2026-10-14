[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $TenantId,

    [Parameter(Mandatory)]
    [string] $ClientId,

    [Parameter(Mandatory)]
    [string] $OriginalSiteId,

    [Parameter(Mandatory)]
    [string] $CatalogSiteId,

    [Parameter(Mandatory)]
    [ValidateSet('Before', 'After')]
    [string] $Stage
)

$ErrorActionPreference = 'Stop'
$GraphRoot = 'https://graph.microsoft.com/v1.0'
$FinanceFileName = 'CONFIDENTIAL-Finance-Simulation.txt'

function Get-SiteFiles {
    param([Parameter(Mandatory)][string] $SiteId)

    $uri = "$GraphRoot/sites/$SiteId/drive/root/children"
    $response = Invoke-MgGraphRequest -Method GET -Uri $uri
    return @($response.value)
}

function Show-FileNames {
    param([Parameter(Mandatory)][object[]] $Files)

    if ($Files.Count -eq 0) {
        Write-Output '(No files returned)'
        return
    }

    $Files | Select-Object -ExpandProperty name
}

$secret = Read-Host 'Enter the lab app client secret' -AsSecureString
$appCredential = [System.Management.Automation.PSCredential]::new($ClientId, $secret)

try {
    Connect-MgGraph -TenantId $TenantId `
        -ClientSecretCredential $appCredential `
        -NoWelcome

    $context = Get-MgContext
    if ($context.AuthType -ne 'AppOnly') {
        throw "Expected app-only authentication; current auth type is '$($context.AuthType)'."
    }

    Write-Output "Authentication: $($context.AuthType)"

    if ($Stage -eq 'Before') {
        Write-Output "Files visible on the original site before grant reduction:"
        $originalFiles = Get-SiteFiles -SiteId $OriginalSiteId
        Show-FileNames -Files $originalFiles

        $financeFile = $originalFiles | Where-Object name -EQ $FinanceFileName | Select-Object -First 1
        if (-not $financeFile) {
            throw "Expected synthetic file '$FinanceFileName' was not present in the original site's listing."
        }

        $driveUri = "$GraphRoot/sites/$OriginalSiteId/drive"
        $drive = Invoke-MgGraphRequest -Method GET -Uri $driveUri
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "finance-simulation-$([guid]::NewGuid().ToString('N')).txt"

        try {
            Get-MgDriveItemContent -DriveId $drive.id `
                -DriveItemId $financeFile.id `
                -OutFile $tempFile

            Write-Output "`nSynthetic file content ($FinanceFileName):"
            Get-Content -Path $tempFile -Raw
        }
        finally {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        Write-Output 'Files visible on the catalog site after grant reduction:'
        $catalogFiles = Get-SiteFiles -SiteId $CatalogSiteId
        Show-FileNames -Files $catalogFiles

        Write-Output "`nTesting the original-site boundary (expected: 403 Forbidden):"
        $originalUri = "$GraphRoot/sites/$OriginalSiteId/drive/root/children"

        try {
            $null = Invoke-MgGraphRequest -Method GET -Uri $originalUri
            throw 'Boundary test failed: the original-site request succeeded.'
        }
        catch {
            if ($_.Exception.Message -match '(?i)403|forbidden|access denied') {
                Write-Output 'Expected denial confirmed: the original-site request was rejected.'
            }
            else {
                throw
            }
        }
    }
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}
