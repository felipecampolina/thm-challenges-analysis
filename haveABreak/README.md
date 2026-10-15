# Investigation Write-Up - Have a Break (TryHackMe)

**Analyst:** Felipe Campolina  
**Role:** Security Investigator  
**Platform:** TryHackMe  
**Room:** Have a Break  
**Case:** Project HAVEABREAK  
**Reference:** EC-2026-0847-CZ  
**Status:** Completed - 6/6 answers accepted  
**Challenge URL:** https://tryhackme.com/room/haveabreak

> **Ethics and scope:** This write-up covers a fictional investigation in an authorized TryHackMe lab. The room was inspired by a real cargo theft, but all entities, people, documents, and investigative findings in the challenge are fictional. Indicators in this document must not be used to attribute real-world wrongdoing.

---

## Introduction

On March 26, 2026, a refrigerated truck operated by TransEuro Logistics s.r.o. disappeared while transporting approximately 413,793 KitKat units from Italy to Poland. The shipment weighed about 12 tonnes and was expected to cross Austria and the Czech Republic. Missed check-ins and the apparent prior knowledge of the route and monitoring process raised the possibility of insider involvement.

As a CZ Node investigator assigned to Project HAVEABREAK, I examined an ECTA briefing, an anonymous email, a dashcam image, employee records, access logs, and internal communications. The investigation combined email forensics, network intelligence, GEOINT, OSINT, log analysis, and insider-threat analysis.

This write-up reconstructs the investigation chronologically. It deliberately distinguishes three confidence levels:

- **Observed fact:** directly present in an artifact or preserved command output.
- **Investigative hypothesis:** a reasonable interpretation that still requires corroboration.
- **Validated answer:** accepted by TryHackMe, even where the full external verification trail was not preserved.

---

## Objectives

- Identify the VPN service used to send the anonymous email.
- Geolocate the petrol station where the missing vehicle was last seen.
- Determine when the suspicious route-planning action occurred.
- Identify the employee who sent the anonymous tip.
- Identify the employee who leaked the shipment details.
- Resolve the leaker's employee ID to a full name.
- Build a defensible timeline from independent evidence sources.
- Document evidence gaps without presenting unperformed work as fact.

---

## Environment and Evidence

The investigation was performed in a Kali Linux environment using the files supplied by the room.

| Artifact | Investigative purpose |
| --- | --- |
| `ecta_memo.pdf` | Initial briefing and incident context |
| `exhibit_a.eml` | Anonymous email and SMTP metadata |
| `exhibit_b.jpg` | Dashcam image used for geolocation |
| `transeuro_data/employees.csv` | Employee directory and ID correlation |
| `transeuro_data/access_log.csv` | Corporate access and file-operation events |
| `transeuro_data/comms_export.txt` | Internal communications and contextual evidence |


### Tools

| Tool | Purpose | Usage status |
| --- | --- | --- |
| Kali Linux | Investigation environment | Used |
| `pdftotext` | Extract text from the PDF briefing | Documented reproduction command |
| `grep` | Filter CSV and text evidence | Used or proposed as noted per command |
| WHOIS | Identify the IP allocation and ASN | Used; output preserved |
| `curl` / ipinfo.io | Enrich the source IP | Used; relevant output preserved |
| Google Maps | Investigate candidate ORLEN locations | Used; final visual comparison not preserved |
| Epieos | Possible email-to-public-profile correlation | Considered; execution evidence not preserved |
| TryHackMe | Validate the six submitted answers | Used; all answers accepted |

---

## Methodology

1. Read the ECTA briefing and establish the incident scope.
2. Parse the email headers and isolate the client-originating IP.
3. Enrich the IP with WHOIS and network intelligence.
4. Extract visual clues from the dashcam image and evaluate map candidates.
5. Search the route-planning logs for anomalous activity before the theft.
6. Correlate employee activity with internal communications.
7. Separate the tipster from the suspected leaker.
8. Map the leaker's employee identifier to the submitted identity.
9. Validate all six answers in TryHackMe and record evidentiary limitations.

---

## Step-by-Step Investigation

### 1. Establishing the Case Context

The first artifact reviewed was `ecta_memo.pdf`. It established the organization, route, cargo, missed check-ins, and the working theory of insider assistance. It also prioritized two exhibits: an anonymous electronic communication and a photograph captured near the D1 motorway.

A reproducible way to extract the PDF text is:

```bash
pdftotext -layout ecta_memo.pdf -
```

This command preserves the approximate page layout and writes the extracted text to standard output. The source notes identify this as a recommended reproduction command; no terminal output from its execution was preserved.

**Observed facts:**

- The truck belonged to the TransEuro Logistics operation based in Brno.
- It carried approximately 413,793 KitKat units weighing about 12 tonnes.
- Its route ran from Italy to Poland through Austria and the Czech Republic.
- Scheduled check-ins failed.
- ECTA suspected advance knowledge of the route and tracking controls.

**Initial hypothesis:** the theft may have depended on information supplied by a person with access to internal route-planning data.



---

### 2. Email Forensics and VPN Identification

The anonymous email in `exhibit_a.eml` was examined to determine how it reached Gmail's SMTP infrastructure. The relevant message metadata was:

```text
From: "Anonymous" <notmyname2847@gmail.com>
To: redakce@novinybrno.cz
Subject: Nestle truck - this was not random
Date: Thu, 27 Mar 2026 23:14:47 +0100
User-Agent: K-9 Mail for Android
```

The decisive header was:

```text
Received: from [193.32.249.132] ([193.32.249.132])
        by smtp.gmail.com with ESMTPSA
```

This `Received` hop was selected because it records the client connection to Gmail's authenticated SMTP service. Later Google relay addresses would describe message transport inside the provider rather than the sender's network egress.


#### Network ownership lookup

The address was queried with WHOIS:

```bash
whois 193.32.249.132
```

Preserved relevant output:

```text
inetnum: 193.32.249.0 - 193.32.249.255
netname: NET-31173-193-32-249-0-24
country: NL
descr: 31173 Services AB infrastructure in Amsterdam, NL.
org-name: 31173 Services Netherlands
origin: AS39351
```

The result was enriched through ipinfo.io:

```bash
curl -s https://ipinfo.io/193.32.249.132/json
```

Preserved relevant output:

```json
{
  "ip": "193.32.249.132",
  "city": "Amsterdam",
  "region": "North Holland",
  "country": "NL",
  "org": "AS39351 31173 Services AB",
  "timezone": "Europe/Amsterdam"
}
```

**Observed fact:** the SMTP client IP was allocated to infrastructure associated with 31173 Services AB and AS39351.

**Investigative hypothesis:** the infrastructure was being used as a VPN exit node. IP geolocation describes the network endpoint, not the sender's physical location; therefore, it does not place the tipster in Amsterdam.

**Validated answer:** correlation performed during the investigation pointed to **Mullvad**, and TryHackMe accepted that answer.

The preserved WHOIS output alone does not prove the provider relationship. To reproduce this missing step, an investigator should query current and historical ASN/IP ownership sources, reputable VPN exit-node datasets, and Mullvad's published server information where available. The date of each source should be recorded because IP assignments can change. This procedure is documented for reproduction and is not claimed as an executed, preserved verification.


---

### 3. GEOINT: Locating the Last Sighting

`exhibit_b.jpg` contained several mutually reinforcing geographic clues:

- ORLEN branding and petrol-station architecture.
- MYTOCZ signage, consistent with the Czech electronic toll system.
- A reference to the D1 motorway.
- Directional or distance information showing Olomouc at 27 km and Brno at 45 km.
- A layout suitable for heavy-goods vehicles.
- A camera timestamp of March 26, 2026 at `22:31:07`.

The memo further stated that the dashcam media came from a vehicle stopped near Hulín. These clues narrowed the search to ORLEN facilities near Hulín, Czechia.

An initial candidate at `D1 - 166.5 km, PS 595 01, Velká Bíteš, Czechia` was rejected because it did not fit the principal geographic clues. Candidates in Slovakia and Poland were also inconsistent with the target area. The refined search produced:

```text
Kroměřížská 1281
768 24 Hulín
Czechia
```

**Observed facts:** the image showed the listed brand, road, distance, and toll-system clues, and the memo referenced Hulín.

**Investigative hypothesis:** the combined clues identify the ORLEN petrol station at the address above as the last known sighting location.

**Validated answer:** **Kroměřížská 1281, 768 24 Hulín, Czechia** was accepted by TryHackMe.

The investigation notes do not retain a conclusive side-by-side comparison between `exhibit_b.jpg` and public imagery of the site. To reproduce that verification, compare road geometry, canopy design, forecourt layout, truck access, sign placement, and the direction of travel against dated street-level or satellite imagery. Record the imagery date and avoid relying on branding alone.


---

### 4. Finding the Suspicious Route-Planning Action

The access log was filtered for activity on March 25, the day before the disappearance:

```bash
grep '2026-03-25' access_log.csv
```

The relevant preserved record was:

```text
2026-03-25 22:14:09
Employee: BR-0291
File: ROUTE_IT_PL_Q1_2026.pdf
Action: EXPORT
```

The event was notable for three reasons:

1. The exported file described the Italy-Poland route involved in the case.
2. The export occurred late at night, outside the expected business pattern described in the investigation.
3. It immediately preceded the shipment's departure and disappearance.

**Observed fact:** employee `BR-0291` exported `ROUTE_IT_PL_Q1_2026.pdf` at `22:14:09` on March 25, 2026.

**Investigative hypothesis:** the timing and sensitivity of the file made the export potentially related to the leak. An anomalous export is an indicator, not proof of criminal intent by itself.

**Validated answer:** **22:14:09**.

---

### 5. Identifying the Anonymous Tipster

The email author claimed to work for the carrier and to have noticed unusual activity in an internal system. This created two distinct attribution problems: identify the person who reported the event and identify the person who performed the suspicious export.

#### Rejected hypothesis: BR-0204

An internal message initially made `BR-0204` a candidate:

```text
[2026-03-27 09:14] br0204@transeuro-log.cz

Getting access denied on the IT-PL route folder
this morning. Is anyone else seeing this?
```

This message showed awareness of the route folder but did not connect the employee to the anonymous Gmail account or to the late-night event. The hypothesis was rejected after the answer was not accepted by TryHackMe.

#### Correlation with BR-0312

A later communication showed another employee active during the relevant night:

```text
[2026-03-25 23:41] br0312@transeuro-log.cz

WK13 driver assignments updated — three changes
from the draft, all confirmed.
Notes in the schedule file.
```

The corresponding access event was:

```text
2026-03-25 23:41:17
Employee: BR-0312
File: DRIVER_SCHEDULE_WK13.xlsx
Action: EDIT
```

The employee directory identified `BR-0312` as a dispatch operator associated with the Brno operation. Their late-night activity placed them in a position to notice the earlier route export.

**Observed facts:** `BR-0312` edited the week-13 driver schedule at `23:41:17`, and a matching internal message was sent at `23:41`.

**Investigative hypothesis:** because `BR-0312` was active shortly after the suspicious export and worked in dispatch, the employee may have witnessed the anomaly and later reported it.

**Validated answer:** **BR-0312** was accepted by TryHackMe.

The available evidence does not forensically link the Gmail account to `BR-0312`. A real investigation would seek Gmail subscriber and login records through lawful process, device artifacts, message drafts, IP/session correlation, and verified testimony. The platform validation resolves the challenge question but is not a substitute for those attribution controls.

---

### 6. Identifying the Employee Who Leaked the Route

The analysis returned to `BR-0291`, the account responsible for exporting the route document. An earlier internal warning supplied additional context:

```text
[2026-03-24 09:11] br0255@transeuro-log.cz

Reminder to all staff — personal email addresses
must not be used for accessing or sharing company files.

This morning a request was received from an
external address (kraliknovak09@gmail.com)
to access files in the route planning shared folder.

The request was blocked.
```

This message establishes an attempted policy violation involving the route-planning folder. It does not, on its own, establish who controlled the external account.

**Observed facts:**

- `kraliknovak09@gmail.com` requested access to the route-planning shared folder.
- IT blocked the request and reminded staff not to use personal accounts.
- `BR-0291` exported the relevant Italy-Poland route PDF the following evening.

**Investigative hypothesis:** the external access attempt and subsequent export may represent two stages of an effort to remove route information from the corporate environment.

**Validated answer:** TryHackMe accepted **BR-0291** as the employee responsible for the leak.

---

### 7. Resolving the Leaker's Full Name

The final task required resolving the suspected leaker to a name. The external address under investigation was:

```text
kraliknovak09@gmail.com
```

The resolution notes considered using Epieos to identify public service or profile associations, potentially including a Google Maps identity. The name reached during the investigation was:

```text
Radovan Blšťák
```

**Observed fact:** the investigation package contained the external email address. The supplied report records the name above as the identity submitted during the challenge.

**Investigative hypothesis:** publicly exposed account associations may connect that address to the named individual and, through the employee data, to `BR-0291`.

**Validated answer:** **Radovan Blšťák** was accepted by TryHackMe.

No Epieos result or public-profile screenshot was preserved. Therefore, this write-up does not claim that the email-to-identity lookup was independently reproduced. A reproducible procedure would query the address through a lawful OSINT service, capture the result with date and source, validate the profile across independent attributes, and then compare it with `employees.csv`. Investigators should respect privacy, applicable law, and service terms.



---

## Consolidated Timeline

| Date and time | Event | Source | Confidence |
| --- | --- | --- | --- |
| 2026-03-24 09:11 | IT warns that `kraliknovak09@gmail.com` requested access to the route-planning folder | `comms_export.txt` | Observed |
| 2026-03-25 22:14:09 | `BR-0291` exports `ROUTE_IT_PL_Q1_2026.pdf` | `access_log.csv` | Observed |
| 2026-03-25 23:41 | `BR-0312` reports updates to week-13 driver assignments | `comms_export.txt` | Observed |
| 2026-03-25 23:41:17 | `BR-0312` edits `DRIVER_SCHEDULE_WK13.xlsx` | `access_log.csv` | Observed |
| 2026-03-26 | Truck departs Italy with the KitKat shipment | `ecta_memo.pdf` | Observed in briefing |
| 2026-03-26 22:31:07 | Dashcam records the suspected last sighting near an ORLEN station | `exhibit_b.jpg` | Observed image timestamp; location validated by THM |
| 2026-03-27 09:14 | `BR-0204` reports access problems with the IT-PL route folder | `comms_export.txt` | Observed |
| 2026-03-27 23:14:47 +0100 | Anonymous message is sent to the journalist | `exhibit_a.eml` | Observed |
| 2026-03-28 | Case is documented in the ECTA memo | `ecta_memo.pdf` | Observed in briefing |


---

## Evidence and Indicators

| Type | Indicator | Relevance | Evidentiary status |
| --- | --- | --- | --- |
| IP address | `193.32.249.132` | SMTP client origin | Observed in email header |
| ASN | `AS39351` | Network allocation | Observed in WHOIS/ipinfo output |
| Organization | 31173 Services AB | Infrastructure operator | Observed in enrichment output |
| VPN provider | Mullvad | Anonymous email egress service | Validated by TryHackMe; external mapping not preserved |
| Email | `notmyname2847@gmail.com` | Anonymous tip account | Observed |
| Email | `kraliknovak09@gmail.com` | External route-folder request | Observed in internal communications |
| Employee | `BR-0312` | Anonymous tipster | Validated by TryHackMe; direct account link not preserved |
| Employee | `BR-0291` | Shipment-information leaker | Export observed; attribution validated by TryHackMe |
| File | `ROUTE_IT_PL_Q1_2026.pdf` | Sensitive route document | Observed in access log |
| File | `DRIVER_SCHEDULE_WK13.xlsx` | Dispatch schedule | Observed in access log |
| Road | D1 | Geographic corridor | Observed in image |
| Address | Kroměřížská 1281, 768 24 Hulín, Czechia | Last-sighting petrol station | Validated by TryHackMe; visual comparison not preserved |
| Person | Radovan Blšťák | Leaker's identity | Validated by TryHackMe; OSINT capture not preserved |

### Evidence Assessment

| Finding | What the evidence supports | What it does not prove by itself |
| --- | --- | --- |
| SMTP source IP | The client reached Gmail from a specific network endpoint | The sender's physical location or human identity |
| Late-night route export | `BR-0291` exported the relevant document at an unusual time | Motive, onward transfer, or criminal intent without corroboration |
| External sharing request | A personal Gmail account requested route-folder access | Who controlled the account |
| `BR-0312` late-night activity | The dispatch employee was active shortly after the export | Ownership of the anonymous Gmail account |
| Accepted TryHackMe answers | The six responses are correct in the lab scenario | A real-world forensic attribution standard |

---

## Commands and Preserved Results

The following commands are the complete command set documented by the source report. Commands without preserved output are explicitly marked as reproduction procedures.

### PDF extraction - reproduction procedure

```bash
pdftotext -layout ecta_memo.pdf -
```

### IP ownership - executed, relevant output preserved

```bash
whois 193.32.249.132
```

```text
inetnum: 193.32.249.0 - 193.32.249.255
netname: NET-31173-193-32-249-0-24
country: NL
descr: 31173 Services AB infrastructure in Amsterdam, NL.
org-name: 31173 Services Netherlands
origin: AS39351
```

### IP enrichment - executed, relevant output preserved

```bash
curl -s https://ipinfo.io/193.32.249.132/json
```

```json
{
  "ip": "193.32.249.132",
  "city": "Amsterdam",
  "region": "North Holland",
  "country": "NL",
  "org": "AS39351 31173 Services AB",
  "timezone": "Europe/Amsterdam"
}
```

### Employee filtering - documented command, output not preserved

```bash
grep -Ei 'BR-0204|BR-0291|BR-0334' employees.csv
```

The original notes preserve this exact command, including `BR-0334`; they do not preserve its output or explain that additional identifier. It is retained for audit fidelity and is not used as evidence in the conclusions.

### Date filtering - documented command, relevant event preserved

```bash
grep '2026-03-25' access_log.csv
```

```text
2026-03-25 22:14:09
Employee: BR-0291
File: ROUTE_IT_PL_Q1_2026.pdf
Action: EXPORT
```

---

## Questions and Validated Answers

| # | TryHackMe question | Validated answer | Basis |
| --- | --- | --- | --- |
| 1 | Which VPN service was used to send the anonymous email from the `.eml` file? | **Mullvad** | SMTP source IP enrichment and platform validation |
| 2 | What is the full street address of the petrol station where the missing vehicle was last seen? | **Kroměřížská 1281, 768 24 Hulín, Czechia** | Image clues, geographic narrowing, and platform validation |
| 3 | At what time did the suspicious action take place in the route planning system on March 25th, 2026? | **22:14:09** | Direct access-log record |
| 4 | What is the employee ID of the person who sent the anonymous email? | **BR-0312** | Temporal/role correlation and platform validation |
| 5 | What is the employee ID of the employee responsible for leaking the shipment details? | **BR-0291** | Direct export record, contextual correlation, and platform validation |
| 6 | What is the leaker's full name? | **Radovan Blšťák** | Recorded OSINT conclusion and platform validation |

---

## Defensive Recommendations

### Data access and loss prevention

1. Apply least privilege to route plans, driver schedules, and live shipment data.
2. Use Data Loss Prevention controls to block or require approval for exports of sensitive logistics documents.
3. Prevent sharing corporate files with unmanaged personal accounts and alert on attempted exceptions.
4. Watermark sensitive exports and maintain auditable document lineage.

### Identity and access management

1. Require phishing-resistant MFA for route-planning and dispatch systems.
2. Use contextual access policies based on managed device status, location, time, and user risk.
3. Review privileged and high-impact access regularly and revoke unnecessary permissions promptly.
4. Separate view, edit, export, and external-share permissions.

### Detection and response

1. Send authentication, file-access, export, and sharing logs to a SIEM.
2. Alert on bulk or unusual exports, off-hours access, first-time sharing destinations, and access to routes outside an employee's duties.
3. Correlate document actions with endpoint, identity, email, and proxy telemetry.
4. Synchronize systems with trusted time sources and retain logs long enough for investigations.
5. Monitor for attempts to bypass blocked sharing through downloads, screenshots, removable media, or personal webmail.

### Operational security

1. Limit distribution of exact route and check-in information until operationally necessary.
2. Segment duties so that no single employee can retrieve all route, cargo, driver, and monitoring details without oversight.
3. Use tamper-resistant vehicle tracking and define an immediate escalation process for missed check-ins.
4. Conduct insider-threat training while maintaining proportionate monitoring and employee privacy.

### Whistleblower protection

1. Provide a secure internal reporting channel that does not require employees to use personal email or consumer VPN services.
2. Protect reporter confidentiality, restrict access to case data, and publish a non-retaliation policy.
3. Preserve reports through a formal chain-of-custody process.

---

## Limitations

Four conclusions were accepted by the platform but lack a fully preserved independent verification trail:

- The external mapping from `193.32.249.132` to Mullvad.
- A definitive visual comparison between the petrol station and public map imagery.
- A direct technical link between the anonymous Gmail account and `BR-0312`.
- A captured OSINT result linking the personal email address to Radovan Blšťák.

These gaps do not change the six accepted challenge answers. They do affect how strongly each conclusion can be represented outside the lab. Accordingly, this report labels them as validated answers rather than overstating them as independently proven forensic facts.

---

## Conclusion

The Have a Break investigation demonstrates how a seemingly small set of heterogeneous artifacts can reveal an insider-enabled cargo theft scenario. Email headers exposed a VPN egress IP; visual clues narrowed the truck's last known location; access logs revealed a sensitive after-hours export; and internal communications helped separate the whistleblower from the suspected leaker.

The reconstructed sequence identified `BR-0312` as the anonymous tipster and `BR-0291`, associated in the challenge with **Radovan Blšťák**, as the source of the leaked shipment information. All six answers were accepted by TryHackMe.

The strongest lesson is methodological: observations, hypotheses, and validated challenge answers are not interchangeable. A professional investigator should preserve original artifacts, record command output, normalize timestamps, corroborate OSINT, and communicate uncertainty as carefully as the final conclusion.

---

## Lessons Learned

- Email `Received` headers must be interpreted hop by hop; not every IP belongs to the sender.
- VPN exit-node geolocation identifies infrastructure, not a person's physical location.
- GEOINT becomes more reliable when road signs, distances, brands, geometry, and travel direction converge.
- An after-hours export is a high-value lead but requires corroboration before attributing intent.
- Temporal proximity can identify a plausible witness, but it does not prove account ownership.
- Rejected hypotheses, such as the initial `BR-0204` theory, should remain in the case record because they demonstrate how alternatives were tested.
- Platform validation confirms a lab answer; real-world attribution requires a documented and reproducible evidentiary chain.

**Final status: challenge completed - 6/6 answers accepted.**
