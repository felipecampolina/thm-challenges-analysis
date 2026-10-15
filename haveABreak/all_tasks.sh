#!/bin/bash

# Have a Break - Investigation command reference
# Run only with the evidence supplied by the authorized TryHackMe room.
# Usage: ./all_tasks.sh [EVIDENCE_DIRECTORY]
#
# This script reproduces only the local and network queries documented in the
# investigation notes. GEOINT, identity attribution, and TryHackMe answer
# validation remain manual analytical steps.

set -u

EVIDENCE_DIR="${1:-.}"

cd "$EVIDENCE_DIR" || exit 1

# 1. Extract the ECTA briefing while retaining its approximate page layout.
# The text is written to standard output.
pdftotext -layout ecta_memo.pdf -

# 2. Investigate the SMTP client IP recovered manually from exhibit_a.eml.
whois 193.32.249.132
curl -s https://ipinfo.io/193.32.249.132/json

# Preserved findings:
# - Netblock: 193.32.249.0/24
# - Organization: 31173 Services AB
# - ASN: AS39351
# - Validated VPN answer: Mullvad
#
# The WHOIS result alone does not prove the Mullvad association. Confirm the
# relationship with dated ASN/VPN infrastructure sources before treating it as
# independently verified.

# 3. Review the employee records referenced in the original investigation.
# BR-0334 is retained because it appeared in the documented command, although
# its output and relevance were not preserved in the investigation notes.
grep -Ei 'BR-0204|BR-0291|BR-0334' transeuro_data/employees.csv

# 4. Review all access-log activity from the night before the disappearance.
grep '2026-03-25' transeuro_data/access_log.csv

# Relevant preserved event:
# 2026-03-25 22:14:09
# Employee: BR-0291
# File: ROUTE_IT_PL_Q1_2026.pdf
# Action: EXPORT

# 5. Manual evidence-correlation checklist
# - Inspect exhibit_a.eml and preserve the complete Received-header chain.
# - Review exhibit_b.jpg for ORLEN, MYTOCZ, D1, Olomouc, Brno, and timestamp clues.
# - Correlate access_log.csv with comms_export.txt and employees.csv.
# - Treat BR-0204 as a rejected hypothesis, not as the anonymous tipster.
# - Distinguish observed evidence from answers validated by TryHackMe.

# Validated TryHackMe answers:
# 1. Mullvad
# 2. Kroměřížská 1281, 768 24 Hulín, Czechia
# 3. 22:14:09
# 4. BR-0312
# 5. BR-0291
# 6. Radovan Blšťák
