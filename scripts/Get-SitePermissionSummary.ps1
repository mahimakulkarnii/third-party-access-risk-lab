[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $SiteId
)

$ErrorActionPreference = 'Stop'

$context = Get-MgContext
if (-not $context) {
    throw 'Connect to Microsoft Graph first with an account authorized to inspect this lab site.'
}

# This inventory uses the operator's authorized Graph session. It is separate
# from the app-only session used to test the simulated vendor's effective reach.
$permissions = Get-MgSitePermission -SiteId $SiteId -All

$summary = foreach ($permission in $permissions) {
    $identities = @($permission.GrantedToIdentitiesV2)
    if ($identities.Count -eq 0) {
        $identities = @($permission.GrantedToIdentities)
    }

    $applications = @(
        $identities |
            ForEach-Object { $_.Application } |
            Where-Object { $_ -and $_.Id }
    )

    if ($applications.Count -gt 0) {
        foreach ($application in $applications) {
            [PSCustomObject]@{
                PermissionId = $permission.Id
                PrincipalType = 'Application'
                DisplayName = $application.DisplayName
                ApplicationId = $application.Id
                Roles = @($permission.Roles) -join ', '
            }
        }
    }
    else {
        [PSCustomObject]@{
            PermissionId = $permission.Id
            PrincipalType = 'Other or unresolved'
            DisplayName = $null
            ApplicationId = $null
            Roles = @($permission.Roles) -join ', '
        }
    }
}

$summary | Format-Table -AutoSize
