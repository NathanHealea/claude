# Accessibility — WCAG 2.1 Level AA

The target is WCAG 2.1 Level AA: conforming means meeting every Level A **and** every Level AA success criterion. There are 30 Level A and 20 Level AA criteria in WCAG 2.1. Source: [WCAG 2.1](https://www.w3.org/TR/WCAG21/).

Cite findings by number, title, and level — "SC 1.4.3 Contrast (Minimum), Level AA" — so the user can look it up and argue with you.

## What a code review can and cannot decide

Reading source settles some criteria outright and only raises questions about others. Say which you are doing.

**Decidable from source:** missing `alt`, missing form labels, a `div` with a click handler and no keyboard path, heading levels that skip, a missing `lang`, `outline: none` with no replacement, a fixed `px` container that cannot reflow, a live region that does not exist.

**Not decidable from source:** whether alt text is *accurate*, whether focus order *makes sense*, whether an error message is *helpful*, whether contrast passes when the color comes from a theme variable resolved at runtime. Flag these as "needs a rendered check" and say what to check. Do not assert a pass or a fail you cannot see.

**Never claim a page conforms.** A source review cannot establish conformance. It can only find failures.

---

## Perceivable

**1.1.1 Non-text Content (A).** Every `<img>`, `<area>`, `<input type="image">`, and SVG conveying meaning needs a text alternative. Decorative images take `alt=""` — present and empty, not absent. Icon-only buttons need an accessible name, from `aria-label`, visually hidden text, or a `<title>` in the SVG. Flag a missing `alt` attribute as a failure; flag alt text you cannot judge ("image", "photo", the filename) as needing a human check.

**1.2.2 Captions (Prerecorded) (A)** and **1.2.5 Audio Description (Prerecorded) (AA).** Any `<video>` or embedded player. In source, look for a `<track kind="captions">` or the player's caption configuration. Its absence is a finding; its presence does not prove the captions are correct.

**1.3.1 Info and Relationships (A).** The most-failed criterion in practice, and the most visible in source. Structure that is conveyed visually must also exist in markup:

- Headings are `<h1>`–`<h6>`, not a styled `<div>` or `<p class="heading">`. Levels do not skip.
- Lists are `<ul>`, `<ol>`, `<dl>`.
- Data tables use `<th>` with `scope`, and a `<caption>`. A table used for layout is a separate problem.
- Every form control has a programmatic label: `<label for>`, a wrapping `<label>`, `aria-label`, or `aria-labelledby`. A `placeholder` is not a label — it disappears on input.
- Related controls are grouped in `<fieldset>` with a `<legend>`. Radio groups especially.
- Required and invalid states are on the element (`required`, `aria-required`, `aria-invalid`), not only in the styling.
- Landmarks: `<main>`, `<nav>`, `<header>`, `<footer>`, or their ARIA equivalents.

**1.3.5 Identify Input Purpose (AA).** Inputs collecting the user's own information carry the right `autocomplete` token — `name`, `email`, `tel`, `street-address`, `postal-code`. Missing `autocomplete` on a personal-data form is a finding.

**1.4.1 Use of Color (A).** Color is never the only way information is conveyed. In source: an error state that only adds a red border, a required-field indicator that is only color, a chart series distinguished only by hue, a link inside body text with `text-decoration: none` and no other visual difference.

**1.4.3 Contrast (Minimum) (AA).** 4.5:1 for normal text, 3:1 for large text (18pt / 24px, or 14pt / 18.66px bold). Compute it where both colors are literals in the CSS. Where a color comes from a variable, a theme, or a computed value, say the pair needs checking and name the variables rather than guessing.

**1.4.4 Resize Text (AA).** Text must scale to 200% without loss of content or function. In source: `user-scalable=no` or `maximum-scale=1` in the viewport meta tag is a direct failure. Font sizes in `px` are not themselves a failure but are worth a note; fixed-height containers holding text are, because the text clips when it grows.

**1.4.10 Reflow (AA).** Content reflows to a 320 CSS px viewport without two-dimensional scrolling. In source: fixed widths wider than 320px, `white-space: nowrap` on body content, `overflow: hidden` that clips, tables and grids with no small-viewport handling, absolute positioning that assumes a wide canvas.

**1.4.11 Non-text Contrast (AA).** 3:1 for the parts of a control that identify it — borders, focus indicators, toggle states — and for meaningful graphics. A 1px light-grey input border on white fails. Focus rings are the usual offender.

**1.4.12 Text Spacing (AA).** No loss of content when line height goes to 1.5×, paragraph spacing to 2×, letter spacing to 0.12em, word spacing to 0.16em. In source: fixed-height text containers and `overflow: hidden` on text.

**1.4.13 Content on Hover or Focus (AA).** Tooltips, popovers, and hover menus must be dismissible without moving the pointer, hoverable (the pointer can move onto them), and persistent until dismissed. A tooltip that appears on `mouseover` and vanishes on `mouseout` with no `Escape` handling and no focus equivalent fails.

---

## Operable

**2.1.1 Keyboard (A).** Everything operable by mouse is operable by keyboard. The signature failure, and the easiest to find in source: a `<div>` or `<span>` with `onClick` and no `tabindex="0"`, no `role`, and no key handler. Use a `<button>`. A custom widget with a click handler but no `keydown` for Enter and Space fails. Drag-and-drop with no keyboard alternative fails.

**2.1.2 No Keyboard Trap (A).** Focus can always leave. Modals are where this breaks — in source, look for a focus trap that has no Escape path, or an unclosed trap on unmount.

**2.4.1 Bypass Blocks (A).** A skip link, or proper landmarks, so keyboard users can get past repeated navigation.

**2.4.2 Page Titled (A).** Every page and route has a descriptive, unique `<title>`. In a single-page app, check that the title updates on navigation — a static title across routes is a failure.

**2.4.3 Focus Order (A).** Tab order follows meaning. In source: positive `tabindex` values (anything above 0) are almost always wrong, and CSS that reorders content visually — `flex-direction: row-reverse`, `order`, `grid-area` — creates a mismatch between reading order and DOM order.

**2.4.4 Link Purpose (In Context) (A).** "Click here", "read more", "learn more" repeated across a page. Also an `<a>` with no text content — an icon link with no accessible name.

**2.4.6 Headings and Labels (AA).** Headings and labels describe their content. Reviewable in source where they are literals.

**2.4.7 Focus Visible (AA).** `outline: none` or `outline: 0` with no replacement indicator is a direct failure and one of the most common. A replacement must be visible; check it against 1.4.11 too. `:focus-visible` used correctly is fine.

**2.5.1 Pointer Gestures (A).** Anything needing a multipoint or path-based gesture — pinch, swipe-to-delete, a slider dragged along a path — has a single-pointer alternative.

**2.5.2 Pointer Cancellation (A).** Actions fire on the up event, not the down event, so a user can slide off to cancel. In source: `onMouseDown` or `onPointerDown` performing the action.

**2.5.3 Label in Name (A).** The accessible name contains the visible label text. In source: a button reading "Submit application" with `aria-label="Submit"` fails — voice control users say what they see, and `aria-label` overrides the visible text.

**2.5.4 Motion Actuation (A).** Anything triggered by device motion — shake, tilt — has a UI alternative and can be disabled.

---

## Understandable

**3.1.1 Language of Page (A).** `<html lang="en">`. Missing `lang` is a failure and takes one line to fix.

**3.1.2 Language of Parts (AA).** Passages in another language carry their own `lang`.

**3.2.1 On Focus (A)** and **3.2.2 On Input (A).** Focusing a control does not change context. Changing a control's value does not submit a form, navigate, or move focus unless the user was warned first. In source: `onChange` on a `<select>` that navigates, an input that auto-submits on the last character, focus moved automatically between fields.

**3.2.3 Consistent Navigation (AA)** and **3.2.4 Consistent Identification (AA).** Repeated navigation keeps the same relative order across pages; the same function is labeled the same way everywhere. Reviewable across a directory of templates or components.

**3.3.1 Error Identification (A).** Errors are identified in text, not only by color or an icon, and the erroring field is named.

**3.3.2 Labels or Instructions (A).** Controls have labels; format requirements are stated before the user gets it wrong, not only after.

**3.3.3 Error Suggestion (AA).** When the fix is known, say it. "Invalid input" fails where "Enter the date as MM/DD/YYYY" passes.

**3.3.4 Error Prevention (Legal, Financial, Data) (AA).** Submissions with legal or financial consequence, or that modify user-controlled data, are reversible, checked, or confirmed. In a university system this covers registration, drops and withdrawals, financial aid, payments, and grade submission. A destructive action with no confirmation step is a finding.

---

## Robust

**4.1.1 Parsing (A).** Duplicate `id` attributes, unclosed elements, improper nesting. Note: this criterion exists in WCAG 2.1 but was removed in WCAG 2.2. Report it as 2.1 requires, and say so if the project targets 2.2.

**4.1.2 Name, Role, Value (A).** Every custom control exposes a name, a role, and its current state, and announces state changes. In source: a `role` set with none of the states that role requires (`aria-expanded` on a disclosure, `aria-checked` on a checkbox, `aria-selected` on a tab), an `aria-labelledby` or `aria-describedby` pointing at an `id` that does not exist, a native element's semantics overridden by a wrong `role`, `aria-hidden="true"` on something focusable.

**4.1.3 Status Messages (AA).** A message that appears without focus moving — a validation summary, "3 results found", a toast, a save confirmation — needs `role="status"`, `role="alert"`, or an `aria-live` region that exists in the DOM *before* the message arrives. A live region injected at the same moment as its content does not announce.

---

## Accessibility false positives

- ARIA on an element that is already the right native element. A `<button role="button">` is redundant, not a failure; and the first rule of ARIA is to use the native element instead, so "add ARIA" is rarely the right fix.
- A missing `alt` on an image inside an `aria-hidden` container.
- Contrast computed from a variable you did not resolve. Say it needs checking.
- A keyboard failure on a component whose library already handles keys — check the library before flagging.
- Level AAA criteria. The target is AA. Mention an AAA issue only in the "Preferences" list, labeled AAA.
- Anything `axe`, `pa11y`, or `eslint-plugin-jsx-a11y` already catches, if the project runs them. Run the tool and report its output instead.
- Asserting a pass. A source review finds failures; it does not certify conformance.
