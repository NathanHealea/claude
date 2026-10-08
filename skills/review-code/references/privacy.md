# Privacy — student, HR, and personnel data

This lens exists because the user works in public higher education, where student-data privacy is a hard constraint, not a preference. The governing rule is FERPA — the Family Educational Rights and Privacy Act — implemented at [34 CFR Part 99](https://www.law.cornell.edu/cfr/text/34/part-99).

**This is a code-review heuristic, not a legal determination.** A finding here means "this looks like it discloses an education record and someone who knows the institution's policy should look." Say that. The call belongs to the Registrar and the institution's privacy office, and a review that speaks as if it were their ruling is worse than one that flags and defers.

## The two definitions everything rests on

**Education record** — a record that is (1) directly related to a student and (2) maintained by the institution or by a party acting for it (34 CFR 99.3). That second clause is why a vendor's database, a third-party analytics pipeline, and a log aggregator are in scope: code that hands data to a processor has not moved it out of FERPA, it has moved it somewhere harder to audit.

**Personally identifiable information** (34 CFR 99.3) is broader than an ID number. It includes:

- the student's name, and the names of a parent or other family members;
- the address of the student or the student's family;
- personal identifiers — Social Security number, student number, biometric record;
- indirect identifiers — date of birth, place of birth, mother's maiden name;
- other information linked or linkable to a specific student that would allow identification with reasonable certainty;
- information requested by a person the institution reasonably believes knows the identity of the student.

The "linked or linkable" clause is the one code review keeps running into. A record with the name stripped out but the birth date, ZIP code, major, and cohort left in is still PII. Pseudonymization is not de-identification when the mapping survives somewhere in the system.

## Directory information, and why it is not a safe default

Directory information may be disclosed without consent if the institution has designated it as such and given notice (34 CFR 99.37). The regulation's examples: name, address, telephone listing, email address, photograph, date and place of birth, major field of study, grade level, enrollment status, dates of attendance, participation in officially recognized activities and sports, weight and height of athletic team members, degrees, honors and awards received, and the most recent institution attended.

Two things make this a trap in code:

**A student ID is not directory information.** The regulation explicitly excludes a Social Security number and a student ID number. The narrow exception is an identifier that functions as a user ID for accessing electronic systems and cannot be used on its own to gain access to education records — it needs a PIN, password, or other factor. Code that treats a student number as a public identifier — in a URL, a page title, a log line, an email subject, a CSV filename — is a finding.

**Students can opt out.** A student may block disclosure of their directory information, and that block must be honored. Code that assumes directory fields are always disclosable, with no check of a suppression or FERPA-block flag, is a finding even when the fields themselves are designated. Look for the flag; if the data model has no such field, that is the finding.

## Where the leaks actually are

The survey lists the call sites. Open each one and see what it carries.

**Logs.** The single most common real finding. A student ID, name, or email interpolated into a log line — then shipped to a log aggregator, an APM, or an error tracker. Log the request UUID or an internal surrogate key, never the subject. Check `console.log`, the logger calls, and the format strings.

**Errors and exceptions.** A stack trace or error message carrying the record that caused it. Sentry, Rollbar, and friends capture local variables and request bodies by default. Check what the error handler passes along and whether scrubbing is configured.

**URLs and query strings.** A student ID in a path or query parameter lands in web server logs, proxy logs, browser history, and `Referer` headers sent to third parties. This is disclosure by plumbing, and nobody chose it.

**Analytics and tags.** Google Analytics, Hotjar, a marketing pixel, a session recorder. A page title, a URL, or a custom dimension carrying a student identifier sends an education record to a third party the student never consented to. Session recorders capture form fields.

**Exports, reports, and email.** A CSV or spreadsheet built wider than the request needed. A notification email whose subject line carries the identifier. An attachment sent to an address from user input.

**Test fixtures and seed data.** Real student records copied into a fixture, a seed script, a snapshot test, or a demo database. This is a HIGH finding: it puts records in a repository, a CI log, and every developer's laptop at once. The user's global rules say this data never gets copied into logs, examples, prompts, or files that leave where it lives.

**Prompts and model calls.** Any LLM or external API call carrying a record. Same rule.

**Caches and client storage.** `localStorage`, `sessionStorage`, a service worker cache, or a shared server-side cache holding records past the session, or keyed so one user's entry can be served to another.

**Authorization on read paths.** Covered by the security lens, but the privacy consequence is what makes it HIGH: an endpoint that takes a student ID from the request and authenticates the caller without checking that the caller is entitled to *that* student's record is an unauthorized disclosure, not just a bug. Check every handler that reads an ID from the request.

**Retention.** Records with no deletion path, or a "soft delete" that leaves them queryable. Also the audit trail: 34 CFR 99.32 requires the institution to maintain a record of disclosures. Code that discloses without recording it is a finding.

## HR and personnel data

The user's rules put HR and personnel data in the same category. FERPA does not govern it, but the handling rule is identical: no copying it into logs, examples, fixtures, prompts, or anything that leaves where it lives. Compensation, performance, disciplinary, medical, accommodation, and background-check data all qualify. Employment records maintained solely for an employment relationship are outside FERPA's education-record definition — but a student employee's record can be both, so do not use employment status to argue a record is out of scope.

Health and disability data, and accommodation records, are more sensitive again and may fall under other rules. Flag and defer.

## Severity

**HIGH** — an identifier or record leaves the system: to a third party, a log aggregator, an email, a repository, or a user not entitled to it. Also real records in a fixture or seed script.

**MED** — a record is exposed somewhere it should not be but stays inside the trust boundary: an over-wide internal query, a cache with no expiry, an ID in an internal URL, a missing disclosure audit entry.

**LOW** — a practice that will become a leak as the code grows: a function that returns the whole record where the caller needs one field, a data model with no suppression flag on a record type that will eventually need one.

## Privacy false positives

- Synthetic or obviously fake data. "Jane Doe", `student@example.com`, `123456789`. Check before flagging.
- An internal surrogate key with no meaning outside the database.
- Aggregate counts with no small-cell problem. A count of 1 in a cross-tab is identifying; a count of 4,000 is not.
- Data the institution has designated as directory information, where the code also checks the suppression flag. Both halves have to be there.
- A field named `student_id` that holds a row ID rather than the institutional number. Read the schema.
- Logging that a request happened, with no subject in it. That is what you want.
- Asserting a FERPA violation. Report what the code does and which rule it appears to touch, and say who should confirm.
