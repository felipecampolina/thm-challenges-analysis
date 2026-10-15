<a id="top"></a>

<div align="center">

# 🛡️ TryHackMe Challenge Solutions & Analysis

### Offensive security, digital forensics and incident investigation — documented step by step

[![TryHackMe Profile](https://img.shields.io/badge/TryHackMe-View_Profile-212C42?style=for-the-badge&logo=tryhackme&logoColor=white)](https://tryhackme.com/p/felipecampolinacc)
![Rooms](https://img.shields.io/badge/Write--ups-7-6C5CE7?style=for-the-badge)
![Focus](https://img.shields.io/badge/Focus-Cybersecurity-00B894?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-FDCB6E?style=for-the-badge)

`Reconnaissance` · `Web Exploitation` · `Privilege Escalation` · `Forensics` · `OSINT`

</div>

> [!IMPORTANT]
> This repository is an educational lab. All documented testing was performed in authorized TryHackMe environments.

## 🧭 Quick Navigation

| [🚩 Write-ups](#-challenge-library) | [🧰 Toolkit](#-tools-commonly-used) | [⚖️ Disclaimer](#disclaimer) | [🤝 Acknowledgements](#-acknowledgements) |
| :---: | :---: | :---: | :---: |


Welcome to my personal repository where I document my **solutions**, **methodologies**, and **technical analysis** of various challenges from [TryHackMe](https://tryhackme.com/). This repository serves both as a learning journal and a resource for others interested in cybersecurity, ethical hacking, and penetration testing.

---

## ✨ About

This project contains detailed walkthroughs and notes for TryHackMe rooms I have completed. Each directory includes:
- Step-by-step solutions
- Tools and techniques used
- Screenshots and code snippets (when applicable)
- Reflections and lessons learned

The rooms cover topics such as:
- Reconnaissance
- Exploitation (Web, Linux, Windows, etc.)
- Privilege Escalation
- Reverse Engineering
- Cryptography
- Capture the Flag (CTF) challenges

---

## 🗂️ Challenge Library

Each folder corresponds to a TryHackMe room, with its own write-up and artifacts.

| Room | Focus | Difficulty | Report |
| :--- | :--- | :---: | :---: |
| 🍫 **Have a Break** | Email forensics, GEOINT and insider-threat analysis | Investigation | [Open write-up](./haveABreak/README.md) |
| 💡 **Light** | SQLite injection and blacklist bypass | Web | [Open write-up](./light/README.md) |
| 🥒 **Pickle Rick** | Web enumeration, command injection and sudo abuse | Easy | [Open write-up](./rickAndMorty/README.md) |
| 🌱 **RootMe** | File upload bypass and SUID escalation | Easy | [Open write-up](./rootMe/README.md) |
| 📹 **Security Footage** | PCAP analysis and image reconstruction | Medium | [Open write-up](./securityfootage/README.md) |
| 📬 **Smag Grotto** | PCAP credentials, command injection and cron abuse | Easy | [Open write-up](./smagGrotto/README.md) |
| 🧱 **Bricks Heist** | WordPress exploitation and threat attribution | Medium | [Open write-up](./tryHack3MBricksHeist/README.md) |

```mermaid
flowchart LR
    A[🔎 Recon] --> B[🧭 Enumeration]
    B --> C[⚡ Exploitation]
    C --> D[🔐 Privilege Escalation]
    D --> E[📝 Evidence & Reporting]

    style A fill:#6c5ce7,color:#fff,stroke:#a29bfe
    style B fill:#0984e3,color:#fff,stroke:#74b9ff
    style C fill:#d63031,color:#fff,stroke:#ff7675
    style D fill:#e17055,color:#fff,stroke:#fab1a0
    style E fill:#00b894,color:#fff,stroke:#55efc4
```

## 🧰 Tools Commonly Used

- `nmap`, `rustscan`
- `gobuster`, `ffuf`
- `Burp Suite`
- `Metasploit`
- `Hydra`, `John the Ripper`, `Hashcat`
- `LinPEAS`, `WinPEAS`, `pspy`
- `Python`, `Bash`, `Go`, `PowerShell`
- `Wireshark`, `tcpdump`

---

<a id="disclaimer"></a>

## ⚖️ Disclaimer

This repository is for **educational purposes only**. All exercises are done on legally permitted platforms like TryHackMe. Do not use any of the techniques or tools documented here on systems you do not own or have explicit permission to test.

---

## 🤝 Acknowledgements

- [TryHackMe](https://tryhackme.com/) for creating such an excellent platform for hands-on cybersecurity training.
- The InfoSec community for sharing knowledge and resources.

---

<div align="center">

Made with ☕, curiosity and responsible hacking.

![Markdown](https://img.shields.io/badge/Built%20with-Markdown-2D3436?style=flat-square&logo=markdown)
![Ethics](https://img.shields.io/badge/Ethics-Authorized%20Labs-00B894?style=flat-square)

</div>
