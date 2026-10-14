# Third-Party SaaS Access Review Lab

![Microsoft 365](https://img.shields.io/badge/Microsoft_365-0078D4?style=flat-square&logo=microsoft365&logoColor=white)
![Entra ID](https://img.shields.io/badge/Entra_ID-5E5E5E?style=flat-square&logo=microsoft&logoColor=white)
![SharePoint](https://img.shields.io/badge/SharePoint-038387?style=flat-square&logo=microsoftsharepoint&logoColor=white)
![Microsoft Graph](https://img.shields.io/badge/Microsoft_Graph-6264A7?style=flat-square&logo=microsoftgraph&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat-square&logo=powershell&logoColor=white)

**Third-party risk · Identity and access review · OAuth app permissions · Data classification · Audit evidence · Least privilege**

I assessed a simulated vendor integration in a controlled Microsoft 365 tenant by testing what its application identity could actually read in SharePoint. The app reached a synthetic confidential-labeled file beyond its stated catalog purpose. I moved its site-level grant to the catalog site, then verified that the intended catalog read still worked and the original-site request was denied.

> **The key finding:** permission review is not complete until the effective data reach is tested. In this lab, a `Sites.Selected` grant still exposed more data than the simulated integration needed.

## Assessment snapshot

| Scope | Evidence-based result |
| --- | --- |
| **Environment** | Personal Microsoft 365 trial tenant with fictional SharePoint content |
| **Identity** | One simulated vendor app using app-only authentication through its service principal |
| **Access model** | Microsoft Graph `Sites.Selected` with explicit site-level read grants |
| **Data model** | Two SharePoint sites and three sensitivity tiers: public, internal, and confidential-labeled |
| **Before remediation** | The app listed files and retrieved a synthetic confidential-labeled finance simulation from the original site |
| **After remediation** | Catalog read succeeded; the original-site request returned `403 Forbidden` |
| **Monitoring result** | Entra sign-ins were visible; file-level audit evidence and retention could not be confirmed |

All lab documents used fictional content and made-up values.

## What I delivered

- **Mapped the access path:** Entra app registration → service principal → app-only token → Microsoft Graph → explicit SharePoint site grant.
- **Tested effective reach:** used Microsoft Graph PowerShell to list and retrieve files as the application identity.
- **Compared reach to purpose:** identified that a simulated catalog integration could also read a confidential-labeled finance simulation.
- **Reduced access:** removed the original-site grant and granted read access to the catalog site.
- **Verified both outcomes:** confirmed the catalog remained readable and the original site returned `403 Forbidden`.
- **Separated authentication from audit evidence:** confirmed service-principal sign-ins but did not treat them as proof of a specific file read.

## Access boundary

```mermaid
flowchart LR
    A[Simulated vendor app] -->|App-only token| B[Microsoft Graph]
    B -->|Explicit read grant| C[SharePoint site]
    C --> D[Synthetic documents]

    classDef app fill:#6C4AB6,color:#fff,stroke:#4B2E83,stroke-width:2px;
    classDef api fill:#4F46E5,color:#fff,stroke:#3730A3,stroke-width:2px;
    classDef site fill:#008577,color:#fff,stroke:#00665B,stroke-width:2px;
    classDef data fill:#F4A261,color:#222,stroke:#D97706,stroke-width:2px;
    class A app;
    class B api;
    class C site;
    class D data;
```

### Access before and after

```mermaid
flowchart TB
    subgraph Before[Before: access exceeded the lab purpose]
        A[Simulated app] -->|Read| B[Original lab site]
        B --> C[Confidential-labeled synthetic file]
    end
    subgraph After[After: access aligned to the catalog use case]
        D[Simulated app] -->|Allowed| E[Catalog site]
        D -.->|403 Forbidden| F[Original lab site]
    end

    classDef app fill:#6C4AB6,color:#fff,stroke:#4B2E83,stroke-width:2px;
    classDef allowed fill:#D1FAE5,color:#065F46,stroke:#059669,stroke-width:2px;
    classDef sensitive fill:#FDE2E2,color:#7F1D1D,stroke:#DC2626,stroke-width:2px;
    classDef blocked fill:#E5E7EB,color:#374151,stroke:#6B7280,stroke-width:2px;
    class A,D app;
    class B,E allowed;
    class C sensitive;
    class F blocked;
```

## Assessment method

### 1. Identify the vendor identity and grant

I registered an Entra application and reviewed the tenant's corresponding service principal. The app used app-only authentication, meaning the application requested access as itself rather than through a signed-in user's permissions. Its `Sites.Selected` application permission was paired with an explicit site-level read grant.

### 2. Test the resource, not just the permission label

I used Microsoft Graph PowerShell to inspect the selected site's permissions, enumerate files, and retrieve a synthetic file. A sanitized example of the read-only listing check:

```powershell
$siteId = "<LAB_SITE_ID>"
$uri = "https://graph.microsoft.com/v1.0/sites/$siteId/drive/root/children"
$files = Invoke-MgGraphRequest -Method GET -Uri $uri
$files.value | Select-Object name, id
```

The assessment used these Microsoft Graph request patterns:

```http
GET /v1.0/sites/{site-id}/permissions
GET /v1.0/sites/{site-id}/drive/root/children
GET /v1.0/sites/{site-id}/drive/items/{item-id}/content
```

The permission request inspects site grants, the children request lists files, and the content request retrieves a file. IDs shown here are placeholders.

### PowerShell test script

The commands shown in the evidence were run interactively during the lab. I consolidated the work into two focused scripts:

- [`scripts/Get-SitePermissionSummary.ps1`](scripts/Get-SitePermissionSummary.ps1) summarizes the explicit app principal and role returned by `Get-MgSitePermission`. Run it in an authorized operator/admin Graph session.
- [`scripts/New-SiteSelectedReadGrant.ps1`](scripts/New-SiteSelectedReadGrant.ps1) recreates the explicit site-level `read` grant. It supports `-WhatIf` and requires an operator/admin context with authority to manage the site's permissions. The grant shown in the evidence was created during the original lab setup.
- [`scripts/Test-VendorAppReach.ps1`](scripts/Test-VendorAppReach.ps1) repeats the app-only read tests. It prompts for the client secret as a secure string, confirms the context is app-only, and removes its temporary file after reading the synthetic finance simulation.

The separate identities matter: the operator session inventories the grant; the app-only session tests what the simulated vendor can actually reach.

Example grant inventory command, after connecting in the authorized operator session:

```powershell
& ./scripts/Get-SitePermissionSummary.ps1 -SiteId "<SITE_ID>"
```

The grant-creation script can preview the request without changing access:

```powershell
& ./scripts/New-SiteSelectedReadGrant.ps1 `
  -SiteId "<SITE_ID>" `
  -ApplicationId "<APP_CLIENT_ID>" `
  -ApplicationDisplayName "Simulated Vendor Integration - Lab" `
  -WhatIf
```

It is a setup aid for a lab site that does not yet have the grant; it is not needed for the already-configured project tenant.

`Test-VendorAppReach.ps1` performs only read-only checks; it does not create, remove, or change permissions. The app and site grants must already be configured for the selected test stage.

```powershell
# Install the Microsoft Graph PowerShell SDK once, if needed
Install-Module Microsoft.Graph -Scope CurrentUser

# Before reducing the grant: list the original site's files and read the synthetic test file
pwsh -File ./scripts/Test-VendorAppReach.ps1 `
  -TenantId "<TENANT_ID>" `
  -ClientId "<APP_CLIENT_ID>" `
  -OriginalSiteId "<ORIGINAL_SITE_ID>" `
  -CatalogSiteId "<CATALOG_SITE_ID>" `
  -Stage Before

# After moving the grant: verify catalog access and the original-site denial
pwsh -File ./scripts/Test-VendorAppReach.ps1 `
  -TenantId "<TENANT_ID>" `
  -ClientId "<APP_CLIENT_ID>" `
  -OriginalSiteId "<ORIGINAL_SITE_ID>" `
  -CatalogSiteId "<CATALOG_SITE_ID>" `
  -Stage After
```

The script is a cleaned-up, reusable version of the captured test flow; the screenshots document the original interactive runs. Replace the placeholders with IDs from an authorized lab tenant. The app needs the selected-site application permission and the corresponding explicit site grants for the selected stage.

### 3. Map data sensitivity to demonstrated reach

| Fictional content | Tier | Role in the test |
| --- | --- | --- |
| Product catalog | **Public** | The simulated integration's intended use case |
| Operations notes | **Internal** | A higher sensitivity tier in the lab inventory |
| Finance simulation | **Confidential-labeled** | Tested whether the app's reach exceeded its purpose |

The finding was based on the data the application could retrieve, not on the permission name alone.

### 4. Review available monitoring evidence

Entra showed successful service-principal sign-ins. A sign-in confirms that the application authenticated; it does not identify which SharePoint file it read. I could not confirm a matching file-level audit event or establish its retention.

The audit configuration query returned `UnifiedAuditLogIngestionEnabled: False`. Microsoft documents that this property can return `False` even when auditing is enabled, so I treated that value as inconclusive rather than proof that audit ingestion was disabled. The detailed assessment is in [findings.md](findings.md).

### 5. Reduce access and verify the boundary

I removed the app's read grant to the original lab site and granted read access to the separate catalog site. I then repeated the Graph tests:

| Retest | Result |
| --- | --- |
| Read the fictional product catalog | **Allowed** |
| Read the original lab site | **Denied — `403 Forbidden`** |

## Findings

| ID | Finding | Disposition |
| --- | --- | --- |
| **VRA-01** | The original site grant let the app retrieve confidential-labeled synthetic content beyond its fictional catalog purpose. | Removed the original grant; moved access to the catalog site; verified the original path was denied. |
| **OBS-01** | File-level audit coverage and retention could not be confirmed from the available evidence. | Recorded as unverified; the configuration query alone was inconclusive. |

Priority reflects demonstrated reach and sensitivity in this controlled exercise. It is not a production risk rating. See **[the detailed findings](findings.md)** for evidence, rationale, and recommendations.

## How I prioritized the findings

The review ranked issues using observed access and business purpose together, then recorded monitoring confidence separately. This keeps a confirmed data exposure distinct from an audit question the lab could not resolve.

| Rank | Finding | Evidence considered | Decision |
| --- | --- | --- | --- |
| **1 · High within this lab** | The app read confidential-labeled content beyond its catalog purpose. | The content retrieval was demonstrated; the sensitivity tier and purpose mismatch were documented. | Remove the original-site grant, move access to the catalog site, and retest both paths. |
| **Evidence gap** | File-level audit evidence and retention were not confirmed. | Entra sign-ins were visible, but the available audit investigation did not establish a corresponding file-read event. | Record coverage as unverified and avoid treating a sign-in as proof of file activity. |

This is a qualitative, evidence-led ranking; it does not imply a numeric score or a production severity assessment.

## Test coverage

The test record connects each control question to the action performed, observed result, and screenshot evidence.

| Test | Check | Observed result | Evidence |
| --- | --- | --- | --- |
| **T-01** | Inspect the explicit site grant | The app had a read grant to the original lab site. | [Grant](screenshots/04-site-scoped-read-grant.png) |
| **T-02** | Enumerate the original site's files | The app listed synthetic files. | [File listing](screenshots/06-vendor-app-visible-files.png) |
| **T-03** | Retrieve the confidential-labeled simulation | Content retrieval succeeded before the grant was reduced. | [Synthetic file read](screenshots/07-vendor-app-read-confidential-simulation.png) |
| **T-04** | Check application sign-ins | Successful service-principal sign-ins were visible. | [Sign-in event](screenshots/08-service-principal-sign-in-log.png) |
| **T-05** | Check file-level audit evidence | A matching event and retention could not be confirmed. | [Audit investigation](screenshots/09-audit-ingestion-disabled.png) |
| **T-06** | Retest the intended catalog use case | Catalog listing succeeded after the grant change. | [Catalog read](screenshots/10-vendor-app-read-catalog-site.png) |
| **T-07** | Retest the original-site boundary | Original-site request returned `403 Forbidden`. | [Boundary test](screenshots/11-vendor-app-boundary-test.png) |

Download the full structured [test matrix](test-matrix.csv) or [data inventory](data-inventory.csv). Both contain synthetic lab information only.

## Evidence gallery

Each section expands to show full-size evidence. Select an image to open it at its original size.

<details>
<summary><strong>Lab setup and synthetic data</strong></summary>

### Entra tenant baseline
<a href="screenshots/01-entra-baseline.png"><img src="screenshots/01-entra-baseline.png" width="900" alt="Entra tenant baseline"></a>

### SharePoint lab site created
<a href="screenshots/01-sharepoint-lab-site-created.png"><img src="screenshots/01-sharepoint-lab-site-created.png" width="900" alt="SharePoint lab site created"></a>

### Private site starting state
<a href="screenshots/02-private-site-home-empty.png"><img src="screenshots/02-private-site-home-empty.png" width="900" alt="Private SharePoint site before test content was added"></a>

### Synthetic data inventory
<a href="screenshots/03-synthetic-data-inventory.png"><img src="screenshots/03-synthetic-data-inventory.png" width="900" alt="Inventory of fictional files at different sensitivity tiers"></a>

</details>

<details>
<summary><strong>Grant and app-only access test</strong></summary>

### Site-scoped read grant
<a href="screenshots/04-site-scoped-read-grant.png"><img src="screenshots/04-site-scoped-read-grant.png" width="900" alt="Explicit site-level read grant for the simulated application"></a>

### App-only request context
<a href="screenshots/05-app-only-site-read-test.png"><img src="screenshots/05-app-only-site-read-test.png" width="900" alt="App-only authentication context and Microsoft Graph site read test"></a>

### Files visible to the simulated app
<a href="screenshots/06-vendor-app-visible-files.png"><img src="screenshots/06-vendor-app-visible-files.png" width="900" alt="Synthetic files listed by the simulated vendor app"></a>

### Confidential-labeled synthetic file read
<a href="screenshots/07-vendor-app-read-confidential-simulation.png"><img src="screenshots/07-vendor-app-read-confidential-simulation.png" width="900" alt="Simulated application retrieving the fictional finance file"></a>

</details>

<details>
<summary><strong>Monitoring, remediation, and retest</strong></summary>

### Entra service-principal sign-in
<a href="screenshots/08-service-principal-sign-in-log.png"><img src="screenshots/08-service-principal-sign-in-log.png" width="900" alt="Successful service-principal sign-in event"></a>

### Audit investigation
<a href="screenshots/09-audit-ingestion-disabled.png"><img src="screenshots/09-audit-ingestion-disabled.png" width="900" alt="Audit investigation output; configuration value treated as inconclusive"></a>

### Catalog access after reduction
<a href="screenshots/10-vendor-app-read-catalog-site.png"><img src="screenshots/10-vendor-app-read-catalog-site.png" width="900" alt="Simulated app reading the fictional catalog after the grant change"></a>

### Final boundary test
<a href="screenshots/11-vendor-app-boundary-test.png"><img src="screenshots/11-vendor-app-boundary-test.png" width="900" alt="Catalog request succeeds and original-site request is denied"></a>

</details>

## Reproduce the exercise

1. Use a Microsoft 365 tenant you own or are authorized to assess.
2. Create two SharePoint lab sites and add fictional documents only.
3. Register a test app and configure the minimum permissions required for the exercise.
4. Grant read access to one site and test file listing and retrieval in an app-only context.
5. Record the data reached and the monitoring evidence you can verify.
6. Remove the first grant, grant access to the intended catalog site, and retest both allowed and denied paths.

Keep credentials outside source control and revoke lab credentials when they are no longer needed.

## Terminology

| Term | Meaning in this assessment |
| --- | --- |
| **Microsoft Entra ID** | Microsoft's identity service, where the app was registered and sign-ins were reviewed. |
| **App registration** | The application's definition, including its configured API permissions. |
| **Service principal** | The application's identity in this tenant. |
| **App-only access** | The application acts as itself, without a user acting on its behalf. |
| **Microsoft Graph** | The API used to inspect site permissions and test file access. |
| **SharePoint site** | A workspace that stores documents and collaboration content. |
| **`Sites.Selected`** | An app permission that requires an explicit grant to each selected site. |
| **`403 Forbidden`** | The response observed when the app requested the original site after its grant was removed. |
| **Audit coverage** | Whether relevant activity can be found and its retention established. A sign-in alone does not prove a specific file read was logged. |

## References

- [Selected permissions in OneDrive and SharePoint](https://learn.microsoft.com/en-us/graph/permissions-selected-overview)
- [List site permissions with Microsoft Graph](https://learn.microsoft.com/en-us/graph/api/site-list-permissions?view=graph-rest-1.0)
- [Create a site permission with Microsoft Graph](https://learn.microsoft.com/en-us/graph/api/site-post-permissions?view=graph-rest-1.0)
- [Search the audit log in Microsoft Purview](https://learn.microsoft.com/en-us/purview/audit-search)
- [Microsoft 365 audit log activities for SharePoint](https://learn.microsoft.com/en-us/purview/audit-log-activities)
