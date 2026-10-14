# Access Review Findings

## Assessment context

This record summarizes a controlled Microsoft 365 lab assessment of one simulated Entra application. The app used app-only authentication and Microsoft Graph `Sites.Selected` with explicit site-level read grants. The sites and files contained fictional content only.

Priority reflects the lab evidence: the sensitivity label of the synthetic resource reached, the intended app purpose, and available monitoring evidence. It is not a production risk rating.

## Prioritized findings

### VRA-01 — App read grant reached confidential-labeled synthetic content

| Field | Observation |
| --- | --- |
| Priority | High within this lab review |
| Access path | Simulated vendor app → app-only token → Microsoft Graph → explicit site-level read grant |
| Intended purpose | Read a fictional public product catalog |
| Demonstrated reach before reduction | App listed files and retrieved `CONFIDENTIAL-Finance-Simulation.txt` from the original lab site |
| Data | Fictional finance summary with made-up values; no real financial, customer, or personal data |
| Monitoring | Entra service-principal sign-in was visible. File-level event evidence and retention were not demonstrated. |
| Status | Remediated in the lab and retested |

**Why it matters:** The app's demonstrated reach exceeded the lab purpose. The issue was established by testing what the app could actually read, then comparing that reach to the fictional catalog use case.

**Action taken:** Removed the app's site grant to the original lab site. Granted read access to a separate catalog site. The app could list `Public-Product-Catalog.docx` from the catalog site, while a request to the original site returned `403 Forbidden` / `Access denied`.

**Recommendation:** For a real integration, grant access only to the specific sites and data required by its documented function. Reassess the grant when the function changes, and retest both allowed and denied paths after changes.

### OBS-01 — File-level audit coverage could not be confirmed

| Field | Observation |
| --- | --- |
| Priority | Monitoring evidence gap; tenant audit state not established by this test |
| Evidence | Entra showed successful service-principal sign-ins. The available audit search did not confirm an event corresponding to the tested file read. |
| Configuration check | `Get-AdminAuditLogConfig` returned `UnifiedAuditLogIngestionEnabled: False`; an attempt to change the value returned an error. This value alone is inconclusive. |
| Impact | The lab could not demonstrate that the tested SharePoint file read appeared in audit search or establish its retention. |
| Status | File-level coverage and retention remain unverified. |

**Why it matters:** A service-principal sign-in event shows the application authenticated. It does not by itself show which SharePoint file the app read. Microsoft documents that `UnifiedAuditLogIngestionEnabled` can return `False` even when auditing is enabled, so the queried value is not proof that audit ingestion was disabled. The assessment could not establish file-level audit evidence or retention.

**Recommendation:** Have a tenant administrator review the Microsoft 365 audit configuration and prerequisites. Then perform a controlled read of a synthetic file, search for a corresponding file activity, and verify event details and retention before relying on that audit path. See [Microsoft Purview audit search](https://learn.microsoft.com/en-us/purview/audit-search) and [audit log retention policies](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies).

## Expected access reviewed

The catalog site's read grant matched the simulated application's stated function. The app could read the fictional public catalog after the grant was moved. This was treated as expected access in the lab, while the original site's access was removed.

## Evidence files

- `04-site-scoped-read-grant.png` — explicit site-level read grant
- `06-vendor-app-visible-files.png` and `07-vendor-app-read-confidential-simulation.png` — demonstrated pre-reduction reach
- `08-service-principal-sign-in-log.png` — successful application sign-in evidence
- `09-audit-ingestion-disabled.png` — tenant configuration query output from the audit investigation; the value is treated as inconclusive
- `10-vendor-app-read-catalog-site.png` — expected catalog access after reduction
- `11-vendor-app-boundary-test.png` — catalog request allowed and original-site request denied

All evidence uses fictional data.
