# Third-Party SaaS Access Review Lab

**Microsoft 365 · Microsoft Entra ID · SharePoint Online · Microsoft Graph · OAuth app permissions · Access review · Audit evidence**

> **The question this lab answers:** If a simulated vendor integration is given access to company data, what can it actually reach, can that access be narrowed, and what evidence would show its activity?

## Executive summary

I built a controlled Microsoft 365 lab using two SharePoint sites, fictional documents, and an Entra application named **Simulated Vendor Integration - Lab**. I granted the app site-specific read access, authenticated as the application, and used Microsoft Graph requests to test the files it could reach.

The app could read a synthetic file marked **CONFIDENTIAL** in the lab inventory. I removed the app’s grant to that site, granted read access to a separate site containing a fictional public product catalog, and tested both paths again. The app could read the catalog; its request to the original site returned **403 Forbidden**.

I also checked available monitoring evidence. Entra showed application sign-in activity. I could not verify file-level audit-event ingestion and retention, so I documented that coverage as **unverified**.

**This is a personal, controlled lab using synthetic data.** It demonstrates a site-level access-review method against a simulated application.

## At a glance

| | |
| --- | --- |
| **Environment** | Microsoft 365 trial tenant controlled by me |
| **Identity** | Entra app registration and its service principal |
| **Data stores** | Two SharePoint Online lab sites |
| **Permission under review** | Microsoft Graph Sites.Selected application permission with explicit site-level grants |
| **Test context** | App-only authentication; no signed-in user acting on behalf of the app |
| **Evidence collected** | Site grant, app-only file listing/read, Entra service-principal sign-in, audit investigation, post-change boundary test |
| **Data** | Fictional catalog, operations notes, and finance simulation |
| **Result** | Read access narrowed to the catalog site; original site returned 403 after its grant was removed |
| **Audit conclusion** | Application sign-in was visible; file-level audit coverage could not be confirmed |

## Why I built this lab

Vendor risk becomes concrete when we can trace a grant to the data it reaches. A permission label alone does not answer whether an integration can see a particular site or file. This lab follows the access path, tests the effective reach, records what monitoring evidence exists, and verifies a reduction with a second test.

The exercise is deliberately small enough to understand end to end:

1. Create a simulated application identity.
2. Grant it access to a specific SharePoint site.
3. Test what it can list and read as an application.
4. Check what the available logs can and cannot tell us.
5. Reduce the grant to the intended resource.
6. Retest both the intended path and the removed path.

## Architecture

~~~mermaid
flowchart LR
    A["Simulated vendor app<br/>Entra service principal"] -->|"App-only token"| B["Microsoft Graph API"]
    B -->|"Explicit read grant"| C["Vendor-Catalog-Lab"]
    C --> D["Fictional public product catalog"]
    B -.->|"Grant removed; request denied"| E["Third-Party Access Risk Lab"]
    E --> F["Synthetic internal and confidential-labeled files"]
    A -.->|"Sign-in activity"| G["Entra service-principal sign-in logs"]
    E -.->|"File audit could not be verified"| H["Microsoft 365 audit investigation"]
~~~

### The access boundary in one picture

~~~mermaid
flowchart TD
    subgraph BEFORE["Before reduction"]
        B1["Simulated app"] -->|"read grant"| B2["Original lab site"]
        B2 --> B3["Synthetic confidential simulation was readable"]
    end
    subgraph AFTER["After reduction"]
        A1["Simulated app"] -->|"read grant"| A2["Catalog site"]
        A2 --> A3["Fictional catalog remains readable"]
        A1 -.->|"No site grant: 403 Forbidden"| A4["Original lab site"]
    end
~~~

## Terminology, in plain language

| Term | Meaning in this project |
| --- | --- |
| **Microsoft Entra ID** | Microsoft’s identity service. I used it to register the simulated application and inspect its sign-in evidence. |
| **App registration** | The application definition: its identity and configured API permissions. |
| **Service principal** | The app’s identity inside this tenant when it accesses Microsoft services. |
| **Application permission / app-only access** | The application acts as itself, without a person signing in for each request. |
| **Microsoft Graph** | Microsoft’s API surface. I used Graph requests to inspect the site grant and test SharePoint access. |
| **SharePoint site** | A workspace that stores documents and related collaboration content. The lab files lived here. |
| **Sites.Selected** | A Graph application permission that requires an additional explicit grant to each selected site. By itself, it is not a grant to every site. |
| **403 Forbidden** | The result observed when the app requested the original site after its site-level grant was removed. |
| **Audit coverage** | Whether relevant actions are recorded, can be retrieved, and are retained for investigation. A sign-in event alone does not establish that a file read was audited. |

## Method

### 1. Created the lab environment

I used a Microsoft 365 trial tenant and created the SharePoint lab site. I populated it with fictional files representing different sensitivity tiers:

- PUBLIC-Product-Catalog.txt
- INTERNAL-Operations-Notes.txt
- CONFIDENTIAL-Finance-Simulation.txt

The finance content was invented for the exercise and explicitly stated that it contained no real financial, customer, or personal data.

### 2. Created the simulated vendor identity

I registered **Simulated Vendor Integration - Lab** in Entra ID. For the access test, I used app-only authentication and the Sites.Selected application permission. I then made an explicit read grant to the lab site.

The important review unit was the **effective grant**: application identity + Graph permission + site-specific permission. I did not infer access from the permission name alone; I tested it.

### 3. Tested the app’s actual reach

Using Microsoft Graph PowerShell, I made requests in the app-only context to:

- list files in the granted site; and
- retrieve the synthetic confidential-labeled finance simulation file.

The requests succeeded. This demonstrated that the app’s site grant exposed more sensitivity than the fictional public-catalog purpose required.

### 4. Investigated monitoring evidence

I reviewed Entra service-principal sign-in events and confirmed successful application sign-ins. I also investigated the available Microsoft 365 audit interface and the tenant’s audit-ingestion state.

I could not confirm that individual SharePoint file reads were being ingested and retained in an audit log. I therefore recorded file-level monitoring as **unverified**. This is a meaningful control gap in the lab’s evidence, but it does not prove that every Microsoft 365 file event was absent from every possible logging source.

### 5. Reduced and retested access

I removed the app’s read grant to the original site and created a separate Vendor-Catalog-Lab site for the intended fictional catalog use case. I granted the app read access to that catalog site and repeated the tests:

- Catalog site: the app could list Public-Product-Catalog.docx.
- Original lab site: the request returned **403 Forbidden** / **Access denied**.

The retest showed that the intended catalog path still worked and the removed site path was blocked.

## Finding

See **[findings.md](findings.md)** for the full finding record and recommendation.

| ID | Finding | Why it matters | Lab disposition |
| --- | --- | --- | --- |
| VRA-01 | The simulated app could read synthetic confidential-labeled content through a site-level read grant, although its lab purpose was a public catalog integration. | The app’s demonstrated reach crossed the lab’s sensitivity boundary. In a real environment, the risk would depend on actual data, business need, and controls. | Removed the original site grant, granted access to the catalog site, and retested both paths. |
| OBS-01 | File-level audit coverage could not be confirmed. | Without verified resource-level events and retention, an investigator may not be able to establish which files the app accessed. | Documented as an unresolved lab limitation; no claim of full file monitoring. |

### Risk-ranking logic

I ranked the access issue based on **what the grant reached**, not just how broad a permission name sounded:

1. Identify the app and its effective site grant.
2. Test which resources and files it could actually access.
3. Compare the sensitivity of those files with the app’s stated purpose.
4. Consider whether activity could be evidenced.
5. Confirm whether a reduction blocks the unnecessary path.

The fictional files let me demonstrate how sensitivity and actual resource reach inform an access review.

## Evidence gallery

The screenshots are organized in the [screenshots folder](screenshots/). **Before publishing this repository, redact tenant domains, tenant IDs, site IDs, user names, personal paths, app or service-principal IDs, request IDs, and other account-specific details in every screenshot.** See [Screenshot privacy review](#screenshot-privacy-review) below.

### 1. Environment and synthetic data

#### Entra tenant baseline
![Microsoft Entra tenant baseline](screenshots/01-entra-baseline.png)

*The lab tenant and identity baseline. Redact the account and tenant identifiers before public posting.*

#### SharePoint lab site created
![SharePoint lab site](screenshots/01-sharepoint-lab-site-created.png)

*The lab site appears in the tenant’s active sites.*

#### Empty site before adding test content
![Initial empty lab site](screenshots/02-private-site-home-empty.png)

*The starting state of the private lab site.*

#### Synthetic data inventory
![Fictional data inventory](screenshots/03-synthetic-data-inventory.png)

*Fictional public, internal, and confidential-labeled files used for the access test.*

### 2. Grant and app-only access test

#### Site-scoped read grant
![Site scoped read grant](screenshots/04-site-scoped-read-grant.png)

*PowerShell output showing the site-level read role.*

#### App-only request context
![App-only site read test](screenshots/05-app-only-site-read-test.png)

*The app-only context and Graph request used to test access.*

#### Files visible to the simulated app
![Files visible to simulated app](screenshots/06-vendor-app-visible-files.png)

*The app could enumerate the synthetic files on the granted site.*

#### Synthetic confidential simulation read
![Synthetic confidential simulation read](screenshots/07-vendor-app-read-confidential-simulation.png)

*The app retrieved fictional test content marked confidential in the lab inventory. The values are made up.*

### 3. Monitoring investigation

#### Entra service-principal sign-in
![Entra service principal sign-in log](screenshots/08-service-principal-sign-in-log.png)

*Successful sign-in evidence for the simulated application. Redact request and principal identifiers.*

#### Audit ingestion configuration investigation
![Audit ingestion investigation](screenshots/09-audit-ingestion-disabled.png)

*PowerShell output from the audit-ingestion investigation. Redact server names, request IDs, and local user paths.*

#### Purview audit search investigation
![Purview audit search](screenshots/09-audit-not-enabled-state.png)

*The audit-search interface did not provide confirmation that the tested file activity was being captured.*

### 4. Reduction and verification

#### App access to the catalog site
![Vendor app reading catalog site](screenshots/10-vendor-app-read-catalog-site.png)

*The simulated app can enumerate the fictional public catalog after its grant is moved to the catalog site. Redact the tenant URL and document identifiers.*

#### Final boundary test
![Final app boundary test](screenshots/11-vendor-app-boundary-test.png)

*The catalog request succeeds while the original-site request is denied with 403 Forbidden. Redact tenant and site identifiers, request IDs, and URLs before publication.*

## Screenshot privacy review

I reviewed all **13 PNGs** in the provided screenshot archive. They are useful evidence, but the originals are **not ready for a public GitHub repository**:

- 01-entra-baseline.png shows the tenant name, partial tenant ID/domain, and account identity.
- 01-sharepoint-lab-site-created.png, 02-private-site-home-empty.png, and 03-synthetic-data-inventory.png show the lab tenant/site name; the inventory also shows the file owner’s name.
- 04-site-scoped-read-grant.png, 05-app-only-site-read-test.png, 06-vendor-app-visible-files.png, and 07-vendor-app-read-confidential-simulation.png show the local terminal username/path. Some also show site or Graph request details.
- 08-service-principal-sign-in-log.png shows service-principal identifiers and request IDs.
- 09-audit-ingestion-disabled.png shows a local user path, Exchange server names, and request details.
- 09-audit-not-enabled-state.png contains an audit-search screen; review the header/account area before posting.
- 10-vendor-app-read-catalog-site.png exposes the tenant SharePoint URL and document identifier.
- 11-vendor-app-boundary-test.png contains tenant/site identifiers and request IDs; the current bars do not remove every identifier.

The archive also includes macOS __MACOSX metadata files; do not add those to the repository. Keep only the PNG evidence files in screenshots/.

**Recommended publication step:** make redacted copies of the screenshots, preserving the evidence result but covering identity and tenant metadata with opaque blocks. Use the redacted copies in the public repository. Do not rely on cropping alone if identifiers remain elsewhere in the image.

## Project scope

This project documents a controlled Microsoft 365 lab using one simulated application, two SharePoint sites, and fictional files. The work included creating a site-specific read grant, testing app-only access through Microsoft Graph, reviewing Entra application sign-in evidence, investigating available audit evidence, reducing the app's access, and verifying the final site boundary.

The key observed outcomes were that the app could read the synthetic confidential-labeled simulation before the change, could read the fictional catalog after the change, and received a 403 response when it tried to access the original site after its grant was removed. File-level audit coverage could not be confirmed and is recorded as unverified.

## Reproduction notes and safety

- Run this only in a tenant you own or are authorized to assess.
- Use fictional, non-sensitive test documents.
- Never commit app secrets, passwords, access tokens, or private keys.
- Revoke lab credentials when they are no longer needed.
- Limit application access to the specific resources required for the test.
- Review every screenshot and output file before publishing; redact identities and tenant-specific metadata.
- Do not interpret an Entra sign-in event as proof of a specific file read.

## Repository layout

    .
    ├── README.md
    ├── findings.md
    └── screenshots/
        ├── 01-entra-baseline.png
        ├── 01-sharepoint-lab-site-created.png
        ├── 02-private-site-home-empty.png
        ├── 03-synthetic-data-inventory.png
        ├── 04-site-scoped-read-grant.png
        ├── 05-app-only-site-read-test.png
        ├── 06-vendor-app-visible-files.png
        ├── 07-vendor-app-read-confidential-simulation.png
        ├── 08-service-principal-sign-in-log.png
        ├── 09-audit-ingestion-disabled.png
        ├── 09-audit-not-enabled-state.png
        ├── 10-vendor-app-read-catalog-site.png
        └── 11-vendor-app-boundary-test.png

## Interview version

> I built a controlled Microsoft 365 lab to review a simulated vendor application's SharePoint access. I used an app-only identity and Microsoft Graph requests to verify which synthetic files it could read, investigated the available audit evidence, narrowed its access to a fictional public catalog, and confirmed that the original site returned 403 after its grant was removed. I could confirm application sign-ins, but I could not verify file-level audit coverage, so I documented that limitation.

