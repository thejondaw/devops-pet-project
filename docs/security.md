# Security Issues in API Service

⚠️ This is a test application with intentionally vulnerable dependencies. DO NOT USE IN PRODUCTION!

## Critical & High Severity
1. **path-to-regexp (High)**
   - ReDoS vulnerability in regex handling
   - Current version: 0.1.x
   - Affects: URL routing

2. **semver (High)**
   - Regular Expression Denial of Service
   - Affects: Package version handling

3. **debug (High)**
   - Inefficient Regular Expression complexity
   - Affects: Logging functionality

4. **qs (High)**
   - Multiple Prototype Pollution vulnerabilities
   - Affects: Query string parsing

5. **negotiator (High)**
   - Regular Expression Denial of Service
   - Affects: Content negotiation

6. **fresh (High)**
   - Regular Expression Denial of Service
   - Affects: Cache validation

7. **mime (High)**
   - ReDoS when handling untrusted input
   - Affects: MIME type handling

## Moderate Severity
1. **express (Moderate)**
   - Open Redirect in malformed URLs
   - Current version: 4.13.1

2. **ms (Moderate)**
   - Inefficient Regular Expression complexity
   - Affects: Time string parsing

## Low Severity
1. **cookie**
   - Out of bounds characters in cookie handling
2. **send**
   - Template injection leading to XSS
3. **serve-static**
   - Template injection leading to XSS
4. **express**
   - XSS via response.redirect()
5. **debug**
   - Regular Expression Denial of Service
