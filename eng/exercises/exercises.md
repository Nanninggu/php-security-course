# Exercises: Sections 1–4

PHP Emergency Security Response Lab: From Checking Your Server to Verifying the Patch

- Do all the exercises in the `lab/` folder provided with the course. See `lab/README.md` for how to prepare it.
- Run commands inside the server after getting in with `docker compose exec server bash`.
- Each time you start an exercise, return to the starting state: `docker compose down && docker compose up -d`
- The answers and explanations are in `exercises_solutions.md`. Try it yourself first, then check.
- Information current as of: 2026-11-08

---

## Exercise 1. Three-step quick check (1-1)

Do the three steps from the lesson yourself and fill in the table below.

| Step | Command used | Result |
|---|---|---|
| ① Command-line PHP version | | |
| ① Web-request PHP version and SAPI | | |
| ② Package verdict (before the update) | | |
| ② Package version after the update | | |
| ③ restart-check result before the restart | | |
| ③ restart-check result after the restart | | |

**Question**: If you had checked only the command-line version in ①, what conclusion would you have reached? Why would that conclusion be wrong?

---

## Exercise 2. How many PHPs does this server have? (2-2)

Check with direct commands, without using `runtime-check.sh`.

1. What is the real file that `php` points to on the command line?
2. List every PHP executable installed on this server.
3. Find where Nginx's configuration hands off PHP requests, and write the configuration file path of the process that creates that socket.
4. Every morning cron runs `php /var/www/app/bin/daily-report.php`. Which PHP version does this batch job run on? Run it yourself to find out.
5. Write **three pieces of evidence, each from a different method,** that the PHP handling web requests is 8.3.

**Think about it**: Is the command-line PHP that batch jobs use also a target of PHP2Shell? (Hint: the path an attack comes in through)

---

## Exercise 3. Reading backports (2-3)

1. After `apt update`, write the current version and the update version of php8.3-fpm from `apt list --upgradable`.
2. From the two versions, write the "upstream PHP version" and the "Ubuntu revision" separately.
3. Find and write the following in `apt changelog php8.3-common`.
   - The package version that contains CVE-2026-109618 and CVE-2026-109619
   - One CVE number fixed in the version just before it
4. A colleague says, "The upstream fixed version is 8.3.36 and we are on 8.3.6, so we are definitely vulnerable." Rebut it using the server after the update.

---

## Exercise 4. Verdict practice (2-4)

For each server below, choose **Fixed / Vulnerable / Cannot tell** regarding PHP2Shell (CVE-2026-109618 and 109619), and write the evidence and the next action. (As of 2026-11-08)

| # | Environment | Verdict | Evidence | Next action |
|---|---|---|---|---|
| A | Ubuntu 24.04, `php8.3-fpm 8.3.6-0ubuntu0.24.04.12` | | | |
| B | Ubuntu 22.04, `php8.1-fpm 8.1.2-1ubuntu2.28` | | | |
| C | Official Docker image `php:8.3.35-fpm` | | | |
| D | ondrej PPA `php8.4-fpm 8.4.26-1+ubuntu24.04.1+deb.sury.org+1` | | | |
| E | PHP 7.4.33 built from source yourself | | | |
| F | Shared hosting, the control panel shows "PHP 8.2" | | | |
| G | Official Windows build PHP 8.3.36 (a build without `-1`) | | | |

---

## Exercise 5. First-pass check before restart (3-1)

You check the training data (`/opt/lab/training-data`). This data is a made-up case, and the IPs are ranges reserved for documentation examples.

```sh
bash /opt/lab/tools/triage.sh /opt/lab/training-data
```

1. Write how many times a PHP worker exited abnormally, and the dates and time windows where they are concentrated.
2. Which IP got 502 responses at the same time as the abnormal exits? And what User-Agent did that IP use?
3. Is the request from `198.51.100.77` evidence of a compromise? Write your reason.
4. Which PHP file did this service never have, and how many requests came in to that file?
5. What is the web server account's crontab set up to do?
6. If this were a real server, would it be fine to run `systemctl restart php8.3-fpm` and patch right now? Write three things you should do before that, in order.
7. Write the result for the lab server itself (run `triage.sh` with no argument), and write what you can say and what you cannot say from that result.

---

## Exercise 6. Applying and proving temporary mitigation (3-3)

Assume you are in a situation where you cannot patch right away.

1. Write the values of `memory_limit`, the `ini_set` result, `post_max_size` and `session.upload_progress.enabled` in `runtime.php` before applying.
2. Apply the two settings in the `mitigation/` folder. Write the commands you used to check the syntax before applying, and their results.
3. Write the same four values after applying, and explain why each value changed by linking it to the configuration line.
4. Check the response codes of the three requests below.
   - A multipart request sent to `/index.php`
   - A multipart request sent to `/post.php`
   - A 9MB request sent to `/post.php`
5. **Check the side effects**: In `nginx-lab-limits.conf`, take `import` out of the list of allowed addresses, apply it, and then run `smoke-test.sh`. What fails? What is the lesson from this result?
6. Answer the following questions.
   - Why must you not put the same settings in `.user.ini`?
   - What is the side effect of `memory_limit = -1`, and how does this lab server prepare for it?
   - Since you applied this mitigation, is it fine to patch at next month's regular maintenance?

---

## Exercise 7. Patch it and prove it (4-1, 4-2)

Start from the starting state, update the PHP packages, and fill in the **proof-of-application table** below. In each cell, attach the command output that serves as evidence.

| What was checked | Before the update | After the update · before restart | After restart |
|---|---|---|---|
| php8.3-fpm package version | | | |
| Whether the CVEs are in the changelog | | | |
| `PHP_VERSION` in the web response | | | |
| FPM master process start time | | | |
| Whether the executable has `(deleted)` | | | |
| Smoke test result | | | |

**Questions**

1. Why can you not tell whether the patch was applied from `PHP_VERSION` in the web response?
2. Why compare the process start time with the dpkg record time?
3. If you patched while the mitigation from Exercise 6 was applied, what else should you do after patching?

---

## Exercise 8. Patching a Docker image (4-3)

```sh
docker compose --profile image up -d --build image-app
curl -s http://localhost:8091/
```

1. Write the current version and SAPI. Why is this setup especially risky?
2. Change `FROM` in `image-lab/Dockerfile` to `php:8.3.36-apache`, then run the following in order and write the version after each.
   - `docker compose --profile image restart image-app`
   - `docker compose --profile image up -d image-app`
   - `docker compose --profile image up -d --build image-app`
3. If your production Dockerfile has `FROM php:8.3-apache` (a moving tag), which option do you need to be sure you pull the patched image?
4. Check the digest with `docker buildx imagetools inspect php:8.3.36-apache`, and write a `FROM` line that pins the digest too.

When you are done, change it back to `FROM php:8.3.35-apache`.

---

## Exercise 9. Fixing the smoke test (4-4)

1. Run `smoke-test.sh` and write the result.
2. If you run it again with `service php8.3-fpm stop` in effect, what passes and what fails? Why? (Run `start` when you are done.)
3. **Coding task**: Add a "sign out" check to `smoke-test.sh`. It passes if, after signing out, opening `/board.php` redirects to the sign-in page (`/index.php`). `/opt/lab/tools` is read-only inside the server, so copy the script to `/tmp` and fix it there.
4. If it were a service you run, write five items you must include in the smoke test.

---

## Exercise 10. Lining up scattered records in time order (5-1)

You merge the training data into a single time-ordered table. This data is a made-up case, and the IPs are ranges reserved for documentation examples. Nothing is changed.

```sh
bash /opt/lab/tools/timeline.sh /opt/lab/training-data
```

1. Split the lines in the table into those that look like "normal work" and those to "check separately," and write why you split them that way.
2. How much time is there between when the last abnormal worker exit was recorded and when the PHP file in the `img` folder was created? When did a request to that file first succeed?
3. Who is the owner of the change for that PHP file and for the web server account's crontab, and how does it differ from the deploy account's (`deploy`) change?
4. Write two things the table can say and two things it cannot. (For example, can this table alone confirm a compromise?)
5. Write two records that are **not** in this table, and how you would keep such records in advance on a production server.

---

## Next step

After you learn incident response and operating procedures in Sections 5 and 6, you write a **one-page response report** for the final assignment, bundling the results of these exercises. Do not delete the records from Exercises 1, 5, 6, 7, 9 and 10; keep them.
