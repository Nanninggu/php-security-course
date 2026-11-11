# Exercise Solutions: Sections 1–4

The answer output is the result of running it myself in the 2026-11-08 lab environment (Docker Desktop, linux/arm64). PIDs and times differ on every run, and in an amd64 environment the `arm64` in the output shows as `amd64`.

---

## Exercise 1. Three-step quick check

| Step | Command | Result |
|---|---|---|
| ① Command-line PHP | `php -v` | `PHP 8.4.27 (cli)` |
| ① Web-request PHP | `curl -s http://127.0.0.1/lab/runtime.php` | `8.3.6`, `fpm-fcgi` |
| ② Verdict before the update | `bash /opt/lab/tools/package-check.sh` | PHP 8.3: both CVEs are not in the changelog → vulnerable |
| ② After the update | `dpkg-query -W php8.3-fpm` | `8.3.6-0ubuntu0.24.04.13` |
| ③ Before the restart | `bash /opt/lab/tools/restart-check.sh` | The master shows `/usr/sbin/php-fpm8.3 (deleted)` → a restart is needed |
| ③ After the restart | Run it again after `service php8.3-fpm restart` | No `(deleted)` → it is using the files that are installed now |

**Question**: If you had looked only at the command-line version (8.4.27), you would have concluded "it is a fixed version, so it is safe." But web requests were being handled by a different program (php-fpm8.3, before the patch). PHP2Shell attacks through web requests, so the basis for the verdict is the PHP that handles web requests.

---

## Exercise 2. How many PHPs does this server have?

1. `readlink -f $(which php)` → `/usr/bin/php8.4` (you can also confirm with `update-alternatives --display php`)
2. `/usr/bin/php8.3`, `/usr/bin/php8.4`, `/usr/sbin/php-fpm8.3`
3. `grep -R fastcgi_pass /etc/nginx/sites-enabled/` → `unix:/run/php/php8.3-fpm.sock`. The process that creates this socket is the `php-fpm: master process (/etc/php/8.3/fpm/php-fpm.conf)` that shows up with `ps -eo args | grep [p]hp-fpm`.
4. `php /var/www/app/bin/daily-report.php` → `Daily report (PHP 8.4.27, cli)`. The batch job runs on the command-line PHP (8.4).
5. Examples (any three of these):
   - Nginx's `fastcgi_pass` points to `php8.3-fpm.sock`
   - The FPM master process's configuration file is `/etc/php/8.3/fpm/php-fpm.conf`
   - `PHP_VERSION 8.3.6` and `PHP_BINARY /usr/sbin/php-fpm8.3` in the `runtime.php` response
   - `php.ini /etc/php/8.3/fpm/php.ini` in the `runtime.php` response

**Think about it**: PHP2Shell is an attack that targets the PHP handling web requests. A command-line batch job does not receive external requests directly, so it is far from this attack path. Still, the command-line PHP is part of the same server's PHP, so the principle is to update it too. And when you write the evidence for a verdict, you must write the two separately.

---

## Exercise 3. Reading backports

1. Current `8.3.6-0maysync1`, update `8.3.6-0ubuntu0.24.04.13`
2. The upstream PHP version is `8.3.6` for both. The Ubuntu revisions are `0maysync1` (at the time of the 24.04 release) and `0ubuntu0.24.04.13` (the 13th security and bug fix).
3. - Both CVEs are in `8.3.6-0ubuntu0.24.04.13` (`debian/patches/CVE-2026-109618_109619.patch`, written 2026-10-19).
   - In the version just before, `8.3.6-0ubuntu0.24.04.12`, CVE-2026-92842, CVE-2026-91768, CVE-2026-91769 and others were fixed.
4. Even after the update the upstream version is 8.3.6, but `package-check.sh` judges "CVE-2026-109618 and 109619: in the changelog → fixed." A distribution does not raise the upstream version; it puts only the fix patch into the old version (a backport). That is why a distribution package is judged not by the upstream version number but by the package revision and the changelog.

Note: `0maysync1` is the package from the 2024 release, so besides PHP2Shell it is also missing every security fix after that. This is why you must not expose the lab server to the outside.

---

## Exercise 4. Verdict practice

| # | Verdict | Evidence | Next action |
|---|---|---|---|
| A | Vulnerable | Ubuntu 24.04 fixed both CVEs in `.13`. The `.12` changelog does not have these CVEs. | `apt install --only-upgrade 'php8.3-*'` → restart FPM → confirm it took effect |
| B | Fixed | PHP 8.1's official support has ended, but Ubuntu 22.04 put the same patch into `8.1.2-1ubuntu2.28` (confirmed in the changelog). | Confirm that FPM was restarted. In the long run, plan an upgrade to a supported version |
| C | Vulnerable | An official image uses the upstream version as is. The fixed version for the 8.3 branch is 8.3.36. | Change `FROM` to 8.3.36 or newer, then rebuild and deploy (Exercise 8) |
| D | Vulnerable | A PPA uses the upstream version as is. The fixed version for the 8.4 branch is 8.4.27. | Update the PPA package → restart FPM. Consider the 8.4.27 SimpleXML regression and run a regression check (4-4) |
| E | Vulnerable (if there is no evidence) | There is no official release for 7.4. The PHP security team published source backports for 7.4, 8.0 and 8.1, but without evidence that you applied one, treat it as vulnerable. | Upgrading to a supported version is best. If that is hard right now, apply the backport, build it and keep a record, or use an LTS vendor's package. Meanwhile apply a temporary mitigation (3-3) |
| F | Cannot tell | "8.2" in the control panel alone does not tell you the detailed version (whether it is 8.2.35) or whether a distribution backport was applied. | Ask the hosting company for the detailed version, the date the patch was applied and whether it was restarted (the Appendix A template) |
| G | Fixed (for PHP2Shell) | 8.3.36 is a fixed version. The `-1` is a rebuild that came out on 10/26; the PHP runtime is the same and it only additionally fixes the Brotli library vulnerability (CVE-2026-111497). | Replacing it with 8.3.36-1 is recommended. Especially needed if the application uses automatic decompression in cURL |

---

## Exercise 5. First-pass check before restart

1. 29 times. They are concentrated before dawn: 7 in the 03:00 hour on 10/23, 11 in the 01:00 hour on 10/24 and 11 in the 03:00 hour on 10/24.
2. `203.0.113.45`, with the User-Agent `python-requests/2.32.3`. A script, not a person's browser, sent 52 POSTs.
3. It is not evidence of a compromise. It was a scan looking for common files such as `phpinfo.php` and `.env`, and all of it ended in 404 or 403. Still, it is meaningful as information that this server became a target of probing aimed at version information.
4. `/img/thumb.php`. All 5 requests that came in to this file were answered with 200. A PHP file in the image folder is very likely not a normal deployment artifact (this training file is a dummy with empty content).
5. Every 10 minutes it downloads a script from an external address and runs it with a shell. This is the typical look of a device left behind so the attacker can come back in (persistence).
6. You must not restart right away. The order:
   1. **Preserve evidence**: Copy the logs, the suspicious file and the crontab, with hashes, to a separate storage. Judge whether memory needs to be preserved, and if so, ask a specialist response organization (it disappears on restart).
   2. **Isolate**: Prevent further damage by blocking outside access, separating the service traffic and so on.
   3. **Report**: Tell the responsible person and security contact, and if personal information is involved, check whether you have a duty to report.

   Then you patch. If a compromise is confirmed, the patch is not the end, and it leads on to a rebuild and rotating secrets (Section 5).
7. The lab server's own result is "this check found no signs." What you can say: nothing unusual in the items this script looks at (abnormal worker exits, dropped upstream connections, PHP files in suspicious locations, the web account's crontab and so on). What you cannot say: that it was not compromised. Logs may have been deleted, the default log does not keep request size or body, and there are many traces this script does not look at.

---

## Exercise 6. Applying and proving temporary mitigation

1. Before applying

   ```text
   memory_limit                       128M
   ini_set(memory_limit, 256M)        changed (128M -> 256M)
   post_max_size                      8M
   session.upload_progress.enabled    On
   ```

2. `php-fpm8.3 -t` → `test is successful`, `nginx -t` → `syntax is ok` / `test is successful`
3. After applying

   ```text
   memory_limit                       -1                 <- php_admin_value[memory_limit] = -1
   ini_set(memory_limit, 256M)        refused (stays -1) <- the application cannot change php_admin_value
   post_max_size                      8M                 <- it was 8M already; now fixed as a value the application cannot change
   upload_max_filesize                5M                 <- matched to the service's attachment limit (5MB) (default 2M)
   session.upload_progress.enabled    Off                <- php_admin_flag[...] = off
   ```

4. A multipart request to `/index.php` → **415**; a multipart request to `/post.php` → **302** (allowed, redirects to the sign-in page); a 9MB request to `/post.php` → **413**
5. `XML import` fails (`/import.php` is blocked with 415; result: passed 7 · failed 1). Lesson: mitigation settings can break the service too. Investigate every address that accepts files without missing any, and run the smoke test even after applying the mitigation.
   - Note: if you send a request right after `service nginx reload`, a worker with the previous configuration may answer, so it may still look as if it passes. Wait 1 to 2 seconds before checking.
6. - `.user.ini` and `ini_set()` apply after the request has been interpreted. The attack happens in the step where the request is interpreted, so they are too late. The official PHP advisory also tells you to put it in php.ini or the FPM pool configuration.
   - With `memory_limit = -1`, a single request can use unlimited memory and bring down the whole server. This lab server puts an outer boundary on the whole container with `mem_limit: 1g` in `docker-compose.yml`. On a production server, systemd `MemoryMax` or a cgroup limit does the same job. `RLIMIT_AS` and `RLIMIT_DATA` can instead trigger the vulnerable path, so they are not used.
   - No. As the official advisory says, it is not a complete mitigation, and this is a vulnerability under real exploitation, listed in CISA KEV. Mitigation is only a way to buy time until you patch, so patch as soon as you can.

---

## Exercise 7. Patch it and prove it

| What was checked | Before the update | After the update · before restart | After restart |
|---|---|---|---|
| php8.3-fpm package version | `8.3.6-0maysync1` | `8.3.6-0ubuntu0.24.04.13` | `8.3.6-0ubuntu0.24.04.13` |
| CVEs in the changelog | No | Yes | Yes |
| `PHP_VERSION` in the web response | 8.3.6 | 8.3.6 | 8.3.6 |
| FPM master start time | T0 | T0 (earlier than the dpkg record) | T1 (later than the dpkg record) |
| `(deleted)` on the executable | None | **Yes** | None |
| Smoke test | passed 8 · failed 0 | passed 8 · failed 0 | passed 8 · failed 0 |

1. A distribution package does not raise the upstream version. It is 8.3.6 both before and after the patch, so you cannot tell them apart by `PHP_VERSION`.
2. If a process started before the package replacement, what is loaded in memory is the old code. Only if the start time is later than the dpkg record can you say that the new code is running.
3. Delete the temporary mitigation block you appended to the end of `www.conf` (especially `memory_limit = -1`), check it with `php-fpm8.3 -t`, restart, and check the values again. You may keep the Nginx request limits if they cause no problems for the service. Run the smoke test once more.

The key point is that "smoke test passed" appears in the before-restart column. Even when the feature check passes, the old code can still be running. The feature check and confirming it took effect are different checks.

---

## Exercise 8. Patching a Docker image

1. `PHP_VERSION 8.3.35`, `PHP_SAPI apache2handler`. With Apache mod_php, an attack is possible before the application code runs, so the official PHP advisory names it the most dangerous setup.
2. `restart` → 8.3.35, `up -d` → 8.3.35, `up -d --build` → **8.3.36**. The container is only turned back on with an image already built, and the image changes only when you rebuild it.
3. Make it pull a fresh base image with `docker compose build --pull` (or `docker build --pull`). Otherwise the `php:8.3-apache` you pulled earlier may be used as it is.
4. Example output as of 2026-11-08:

   ```text
   Digest:    sha256:a800bbd2c0aa322702259ed475556b2cbc311076a8d3c4bba9bfe96838745472
   ```

   ```dockerfile
   FROM php:8.3.36-apache@sha256:a800bbd2c0aa322702259ed475556b2cbc311076a8d3c4bba9bfe96838745472
   ```

   The digest changes if the image is rebuilt, so use the value you checked yourself at the time you run it.

---

## Exercise 9. Fixing the smoke test

1. `Result: 8 passed · 0 failed`
2. `Result: 2 passed · 6 failed`. The two items that passed are `CLI batch` (the command-line PHP does not go through FPM) and `No PHP worker crash` (what stopped is not a crash, so the log has no signal record). "No crash" does not mean "working normally."
3. After copying it to `/tmp`, put the following right above the `crash_after=` line.

   ```bash
   curl -s -c "$jar" -b "$jar" -o /dev/null "$BASE/logout.php"
   loc=$(curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{redirect_url}' "$BASE/board.php")
   [[ $loc == */index.php ]] && ok "Sign out (opening the board goes to the sign-in page)" || bad "Sign out (redirected to: ${loc:-none})"
   ```

   ```sh
   cp /opt/lab/tools/smoke-test.sh /tmp/smoke.sh
   # after editing
   bash /tmp/smoke.sh      # Result: 9 passed · 0 failed
   ```

   The other check items need the signed-in state, so put the sign-out at the end.
4. Examples: sign-in and sign-out, flows where money moves such as payment or orders, file upload and download, external API integration (cURL), sending mail, scheduled jobs (cron), the admin screen, image processing (GD, Imagick), other servers that share sessions

---

## Exercise 10. Lining up scattered records in time order

1. Normal work: the files `deploy` changed during working hours (10/21 08:50) and the FPM start. Lines to check separately: the lines where worker exits, dropped connections and 502 responses cluster before dawn and overlap at the same time, the `img/thumb.php` and crontab changed by `www-data`, and `198.51.100.77`'s request for version information files. The reasons are "three different kinds of records at the same time point to the same event" and "the web server account changed code and scheduled job files."
2. The last exit is at 03:02:40 on 10/24 and the file change at 03:58:41, so about 56 minutes later. The first successful request is at 04:02:11 (`POST /img/thumb.php`, response 200). The crontab change comes after that, at 04:06.
3. Both are owned by `www-data` (the web server account). The deploy files were changed all at once by the `deploy` account. What differs is that the web server account changed the code folder and a scheduled job file. But the owner alone does not tell you how it was changed (an upload, a misconfiguration and so on).
4. What it can say: in what order the unusual signs followed one another, and around which times the records need to be preserved. What it cannot say: whether a compromise is confirmed, what was inside the requests (the request body and size are not in the records), how the file was created, and whether there was more data.
5. For example: an access log format that records the request body and size, file integrity records (a list of hashes at deployment time), the authentication log, and a copy of the logs sent off the server. On a production server, if you send logs to another server and save the file list and hashes at each deployment, you can later compare "which files changed."
