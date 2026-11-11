# PHP Security Update Response Report (Template)

> Write it to fit on one page. Delete the `〔 〕` in each cell and fill in the details of your own server.
> For command output, paste **only the key lines, verbatim**, and mask anything that shows a password, token or personal information (`●●●●`).
> Mark what you confirmed from output as fact, and mark everything else **(assumption)**.

| Item | Content |
|---|---|
| Report name | 〔e.g. Response to the PHP security advisory (2026-10-21)〕 |
| Author · date written | 〔name〕 · 〔YYYY-MM-DD〕 |
| Information current as of | 〔the date you checked the advisory and package information〕 |

## 1. Summary

- **Conclusion**: 〔Affected / Not affected / Could not decide〕
- **Remediation status**: 〔Done / Under temporary mitigation / Not remediated〕
- **One-line description**: 〔e.g. Verdict made, patch applied, confirmed the new code is running. Whether there was a compromise needs separate checking〕

## 2. Target

| Item | Content | Command and place used to check |
|---|---|---|
| Server name / role | 〔〕 | — |
| Operating system | 〔〕 | 〔command · your computer / inside the server〕 |
| How the PHP that **handles web requests** runs | 〔mod_php / FPM / container …〕 | 〔command · place〕 (2-2) |
| Command-line (CLI) PHP version | 〔〕 | 〔command · place〕 |

## 3. Check results

| Item | Result | Evidence (key lines of output · time) |
|---|---|---|
| Installed package version | 〔〕 | 〔〕 |
| Whether the distribution changelog includes the fix | 〔Yes / No / Could not confirm〕 | 〔〕 (2-3) |
| Verdict | 〔Affected / Not affected / Could not decide〕 | 〔which source the verdict was based on〕 (2-4) |
| Signs seen in the first-pass check | 〔Present / None found in the records checked〕 | 〔〕 (3-1) |

## 4. Remediation

Write them in time order.

| Time | What I did | Where I ran it | Result |
|---|---|---|---|
| 〔〕 | Preparation before the update (copies of configuration, database and uploads; restore test) | 〔〕 | 〔〕 (3-2) |
| 〔〕 | 〔Package update / image rebuild〕 | 〔〕 | 〔〕 (4-1, 4-3) |
| 〔〕 | 〔Service restart〕 | 〔〕 | 〔〕 |

- **If you used a temporary mitigation**: 〔what you applied and where / its limits / the deadline for replacing it with the formal patch〕 (3-3)

## 5. Verification

| What was checked | Result | Evidence |
|---|---|---|
| Is the worker (process) start time after the update? | 〔〕 | 〔〕 (4-2) |
| Is the code that answers web requests the new code? | 〔〕 | 〔〕 |
| Smoke test | 〔passed n / failed n〕 | 〔the failing lines, if any〕 (4-4) |

## 6. Remaining risk and next steps

| Item | Content | Owner · deadline |
|---|---|---|
| What I could not confirm | 〔e.g. a period with no records kept〕 | 〔〕 |
| Whether there was a compromise | 〔even if you found no signs, do not write "no compromise"〕 | 〔〕 (5-1) |
| Whether a report or notification is needed | 〔confirm with your organization's contact and the latest law〕 | 〔〕 (5-2) |
| Rotating secrets | 〔whether it is needed and what〕 | 〔〕 (5-3) |
| Preparing for end of support | 〔the end-of-support date of the version you use and the migration plan〕 | 〔〕 (6-1) |
| Next regular check | 〔the next date on the monthly checklist〕 | 〔〕 (6-2) |

## Before you submit

- [ ] Every conclusion has its evidence (the key lines of command output) next to it.
- [ ] For each command I wrote **where** (your computer / inside the server) and **when** I ran it.
- [ ] I did not mix up "patched" and "not compromised."
- [ ] I did not write a temporary mitigation as if it were the fix.
- [ ] What I could not confirm is written as "could not confirm."
- [ ] I masked passwords, tokens and personal information.
