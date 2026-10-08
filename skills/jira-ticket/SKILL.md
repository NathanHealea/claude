---
name: jira-ticket
description: Write the text fields for a single Jira ticket - Epic Name (epics only), Summary, and Description - from a short description of the work, and print them as copy-pastable blocks. Use when the user asks for a Jira ticket, a ticket write-up, a story or bug to file, "write this up as a ticket", "make me a Jira story for this", "turn this into a bug ticket", or invokes /jira-ticket. Produces text only; it does not create, update, or query anything in Jira.
---

# Write Jira ticket content

Turn a rough description of some work into the three text fields a Jira ticket
needs, ready to paste into the create-issue form.

**Text only.** This skill never calls Jira, never creates an issue, and never
touches the repository. Its entire output is the blocks printed in chat.

## Invocation

```
/jira-ticket <context>
/jira-ticket <type> <context>
```

`<type>` is optional and is one of `epic`, `story`, `bug`, `task`. When the
first word of the argument is one of those four, it is the type and the rest is
context. Otherwise the whole argument is context.

When no type is given, infer it from the context against the definitions below,
and state the inferred type in one line after the blocks. Do not ask. When the
context does not clearly fit one type, use `task`.

- **epic** — a body of work that will span several tickets.
- **story** — new or changed behavior a user can observe.
- **bug** — existing behavior that is wrong.
- **task** — work with no observable behavior change: refactors, upgrades,
  tooling, infrastructure, documentation.

## Rules

**Use only what the user gave you.** Never invent a component name, a version,
an error message, a user role, a date, a metric, or an acceptance criterion the
context does not support. A thin ticket is fine; a confident wrong one is not.
If something important is missing, leave it out of the ticket and list it under
"Open questions" after the blocks.

**Minimum viable content.** A description that repeats the summary in longer
words is waste. Every line in the description must carry something the summary
does not.

**No placeholders in the output.** No `TBD`, no `<insert component>`, no
bracketed fill-ins. Anything unknown goes in the open questions, not the blocks.

**Strip sensitive data.** Jira tickets are broadly readable. Never carry a real
student name, ID, email, grade, or personnel record into a ticket, even when the
user's context includes one. Describe the record generically ("an enrolled
student", "the affected account") and say in one line that you did so.

**Plain text, no markdown headers.** Jira's editor does not render `#` headings
pasted as text. Use bold labels on their own line, hyphen bullets, and numbered
steps. Keep them intact so the paste survives.

## Field shapes

### Epic Name — epics only

Two to four words naming the body of work. No verb, no ticket-speak. It shows
on every child issue's board card, so long names get truncated.

### Summary — every type

One line, imperative mood, no trailing period. Aim under 80 characters so it is
not truncated in lists and boards. It must be understandable by someone who has
not read the description.

- story / task: complete "when done, this will ___" — `Add SAML logout to the advising portal`
- bug: state the wrong behavior — `Transcript export drops the last enrolled term`
- epic: name the outcome — `Migrate advising portal to the new identity provider`

Do not prefix with the type, the component, or a bracketed tag unless the user
says the project does that.

### Description — every type, shape depends on type

**epic** — two to four sentences: what this covers, why it is being done, and
where it stops. Add an `Out of scope:` line only when the context draws that
line itself.

**story** — one line in the form `As a <role>, I need <capability> so that
<outcome>.`, then `Acceptance criteria:` with two to five hyphen bullets, each
one independently checkable. Use the role the user actually named; if they named
none, describe the behavior in a plain sentence instead of inventing a persona.

**bug** — three labeled parts, in this order:

```
Current behavior:
<what happens now, one or two sentences>

Expected behavior:
<what should happen, one sentence>

Steps to reproduce:
1. <step>
2. <step>
```

Include the steps only when the context supplies them. Add an `Environment:`
line only when the context names a browser, version, or environment.

**task** — two to three sentences: what to change and why it is needed now.
Close with a single `Done when:` line stating the verifiable finish condition.

## Output

Print each field in its own fenced block, labeled, in this order: Epic Name
(epics only), Summary, Description. Nothing between the blocks.

After the blocks, print at most two short lines: the inferred type if you
inferred one, and "Open questions:" with the gaps that would change the ticket.
Skip either line when it does not apply. No summary paragraph, no offer to
revise.

An example of a finished bug ticket, printed exactly in this shape:

**Summary**

```text
Transcript export drops the last enrolled term
```

**Description**

```text
Current behavior:
Exporting an unofficial transcript omits the most recent enrolled term for
students who registered after the drop deadline.

Expected behavior:
The export includes every term the student is enrolled in, including the
current one.

Steps to reproduce:
1. Sign in as a student with a current-term registration added after the drop deadline.
2. Request an unofficial transcript export.
3. Compare the export against the student's term list.
```

Open questions: does this affect official transcripts too?
