# Security Assessment Report – Security Footage (TryHackMe)

**Analyst:** Felipe Campolina  
**Role:** Cybersecurity Analyst / Digital Forensics Investigator  
**Date:** July 2025  
**Platform:** TryHackMe  
**Difficulty:** Medium  
**Challenge URL:** https://tryhackme.com/room/securityfootage

---

## Executive Summary

This report documents a comprehensive forensic analysis of the "Security Footage" challenge from TryHackMe. The objective was to recover security footage from a compromised camera system by analyzing a `.pcap` file and reconstructing video frames.

**Key Findings:**
- **Critical:** Successful extraction of 541 frames from the video stream.
- **High:** Identification of key evidence in frame 229 containing critical information.

**Environment:** Simulated Lab (TryHackMe Platform)  
**Target File:** `security-footage-1648933966395.pcap`

---

## Objective

The goal of this forensic analysis was to simulate a real-world scenario where digital forensics is used to recover critical evidence from network traffic. Main objectives included:

- Analyzing the `.pcap` file to identify the video stream.
- Extracting individual frames from the video stream.
- Reconstructing the security footage to identify key evidence.

---

## Methodology

1. **Network Traffic Analysis**:
   - Used Wireshark to analyze the `.pcap` file and identify patterns in the video stream.

2. **Data Extraction**:
   - Developed a Python script (`extract_images.py`) to process the video stream and extract individual JPEG images.

3. **Reconstruction**:
   - Reviewed the extracted images to identify key frames containing critical information.

---

## Findings

### Network Traffic Analysis

The `.pcap` file was loaded into Wireshark to identify the video stream. Key observations included:
- **Protocol:** HTTP traffic containing video data.
- **Stream:** Identified a continuous video stream embedded in the network traffic.

### Data Extraction

A custom Python script was used to extract JPEG images from the video stream. The script successfully extracted 541 frames.

### Key Evidence

Frame 229 was identified as containing critical information relevant to the investigation.

---

## Tools Used

- **Wireshark**: For analyzing network traffic and identifying the video stream.
- **Python**: For writing a script to extract JPEG images from the video stream.
- **Foremost**: (Optional) For carving files from the `.pcap` file.

---

## Detailed Steps

1. **Load `.pcap` File in Wireshark**:
   - Opened the `.pcap` file in Wireshark.
   - Filtered traffic to identify the video stream.

2. **Extract Video Stream**:
   - Used the `Follow TCP Stream` feature in Wireshark to isolate the video data.

3. **Run Python Script**:
   - Executed `extract_images.py` to process the video stream and extract individual JPEG images.

4. **Review Extracted Frames**:
   - Manually reviewed the extracted frames to identify key evidence.

---

## Results

- Successfully extracted and reconstructed 541 frames from the video stream.
- Identified key evidence in frame 229, which contained critical information.

---

## Remediation Recommendations

### Immediate Actions

1. **Secure Network Traffic**:
   - Implement encryption (e.g., HTTPS) to protect video streams from interception.

2. **Monitor Network Activity**:
   - Deploy intrusion detection systems (IDS) to identify unusual traffic patterns.

3. **Enhance Camera Security**:
   - Use strong authentication mechanisms for accessing camera systems.

### Long-term Improvements

1. **Regular Audits**:
   - Conduct periodic security audits of networked devices.

2. **Incident Response Plan**:
   - Develop and test an incident response plan for compromised devices.

---

## Conclusion & Lessons Learned

### Technical Summary

This forensic analysis successfully demonstrated the recovery of security footage from a compromised camera system. The assessment highlighted the importance of securing network traffic and implementing robust authentication mechanisms.

### Key Security Lessons

**For Network Administrators:**
- Encrypt all sensitive network traffic to prevent interception.
- Monitor network activity for unusual patterns.

**For System Administrators:**
- Regularly update and patch camera systems.
- Implement strong authentication mechanisms.

### Real-World Relevance

The vulnerabilities demonstrated in this challenge mirror common issues found in actual production environments:

1. **Unencrypted Traffic:** Many systems still transmit sensitive data in plaintext.
2. **Weak Authentication:** Default or weak credentials are often used for networked devices.

### Final Thoughts

The "Security Footage" challenge effectively demonstrates the importance of digital forensics in recovering critical evidence. This reinforces the need for comprehensive security measures to protect networked devices and sensitive data.

**Challenge Rating:** ⭐⭐⭐ (Excellent for intermediate-level forensic analysis)
