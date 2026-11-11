# PHP Security Update Response Report (Example)

> **This is a made-up training case.** The server name, times, versions and results are all examples, and are not output from a real run. The command output is shortened to show the format, and on your own server you must paste the real output you ran. The IPs are ranges reserved for documentation examples (`198.51.100.x`).

| Item | Content |
|---|---|
| Report name | Response to the PHP security advisory (2026-10-21) — training server web01 |
| Author · date written | Example owner · 2026-11-10 |
| Information current as of | 2026-11-10 (php.net advisory, Ubuntu package changelog) |

## 1. Summary

- **Conclusion**: Affected (verdict)
- **Remediation status**: Done (package update · worker restart)
- **One-line description**: The web PHP was judged to be in the affected range, so after making copies before the update I upgraded the packages and restarted the workers, and confirmed that the new code is running and the smoke test passes. I found no signs of compromise in the records I checked, but there is a period with no records, so I do not settle whether there was a compromise.

## 2. Target

| Item | Content | Command and place used to check |
|---|---|---|
| Server name / role | web01 · internal notice board (made-up training) | — |
| Operating system | Ubuntu 24.04 | `cat /etc/os-release` · inside the server |
| How the PHP that **handles web requests** runs | Nginx + PHP-FPM | `ps -ef \| grep [p]hp-fpm` · inside the server (2-2) |
| Command-line (CLI) PHP version | Can differ from the web PHP, so not used for the verdict | `php -v` · inside the server |

## 3. Check results

| Item | Result | Evidence (key lines of output · time) |
|---|---|---|
| Installed package version | The package version before the update (example: `8.3.6-0ubuntu0.24.04.x`) | `dpkg -l php8.3-fpm` · inside the server · 10:02 |
| Whether the distribution changelog includes the fix | Included in the candidate version (confirmed) | The lines in the `apt changelog` output that contain both vulnerability numbers · inside the server · 10:05 (2-3) |
| Verdict | **Affected** — the web PHP is FPM, and the installed version's changelog does not have the fix | The two lines above (2-4) |
| Signs seen in the first-pass check | None found in the records checked | Checked the access log, FPM log and file change records · 10:20 (3-1) |

- `PHP_VERSION` in the web response can be the same before and after the patch, so it was not used as evidence for the verdict.

## 4. Remediation

| Time | What I did | Where I ran it | Result |
|---|---|---|---|
| 10:30 | Made copies of the configuration, database and uploads, and tested a restore by unpacking elsewhere | Inside the server | Unpacking succeeded, database integrity check `ok` (3-2) |
| 10:50 | Package update | Inside the server | New package version installed (example) (4-1) |
| 10:55 | Restarted the PHP-FPM service | Inside the server | Started normally |

- **Temporary mitigation**: Not used. (If it had been, write the place applied, its limits and the deadline for the formal patch here.)

## 5. Verification

| What was checked | Result | Evidence |
|---|---|---|
| Is the worker start time after the update? | Yes — the master process start time is later than the package install time | Compared `ps -o lstart` with `dpkg.log` · 10:58 (4-2) |
| `(deleted)` marker on the executable | None | `ls -l /proc/<pid>/exe` · 10:58 |
| Smoke test | All items passed (example: passed 7 / failed 0) | The result line of `smoke-test.sh` · 11:02 (4-4) |

## 6. Remaining risk and next steps

| Item | Content | Owner · deadline |
|---|---|---|
| What I could not confirm | There is a period (example: the last 3 days) in which the access log was not kept | Infrastructure owner · log retention setting by 11-17 |
| Whether there was a compromise | I found no signs in the records I checked, but **I do not settle it as "no compromise."** I will strengthen the file change records and check again | Security owner · 11-17 (5-1) |
| Whether a report or notification is needed | There were no signs, so I did not treat it as reportable, but it must be confirmed with the organization's contact and the latest law | Information security owner · 11-12 (5-2) |
| Rotating secrets | Not rotated because there were no signs of compromise. If a compromise is confirmed, consider rotating the database password and session key | Security owner · when it arises (5-3) |
| Preparing for end of support | Check the end-of-support date of the version in use and make a migration plan | Infrastructure owner · 11-30 (6-1) |
| Next regular check | The next date on the monthly checklist (6-2) | Infrastructure owner · 12-10 |

## How to read it: what this example keeps to

- The conclusion (affected, remediation done) is at the top, and each section below has its evidence.
- It keeps "not found in the records checked" apart from "no compromise."
- What could not be confirmed (the log gap) is written in the remaining risk section.
- It records where (inside the server) and when (the time) each thing was run.
