[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string] $SiteId,

    [Parameter(Mandatory)]
    [string] $ApplicationId,

    [Parameter(Mandatory)]
    [string] $ApplicationDisplayName
)

$ErrorActionPreference = 'Stop'
$GraphRoot = 'https://graph.microsoft.com/v1.0'

$context = Get-MgContext
if (-not $context) {
    throw 'Connect to Microsoft Graph first with an authorized operator/admin identity.'
}

# Creating a site permission is an administrative write. The calling identity
# must have the required Graph authority (for example, Sites.FullControl.All).
$requestBody = @{
    roles = @('read')
    grantedToIdentities = @(
        @{
            application = @{
                id = $ApplicationId
                displayName = $ApplicationDisplayName
            }
        }
    )
} | ConvertTo-Json -Depth 8

$target = "read access for '$ApplicationDisplayName' on the specified lab site"
if ($PSCmdlet.ShouldProcess($target, 'Create explicit Microsoft Graph site permission')) {
    $uri = "$GraphRoot/sites/$SiteId/permissions"
    $permission = Invoke-MgGraphRequest -Method POST `
        -Uri $uri `
        -Body $requestBody `
        -ContentType 'application/json'

    [PSCustomObject]@{
        PermissionId = $permission.id
        Application = $ApplicationDisplayName
        ApplicationId = $ApplicationId
        Roles = @($permission.roles) -join ', '
    }
}
