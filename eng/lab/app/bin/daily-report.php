<?php
// Batch job run by cron every morning (e.g. 0 4 * * * php /var/www/app/bin/daily-report.php)
// It runs from the command line as `php`, so it may use a different PHP from web requests.
require __DIR__ . '/../src/bootstrap.php';

$total = (int)db()->query('SELECT COUNT(*) FROM notices')->fetchColumn();
$withFile = (int)db()->query('SELECT COUNT(*) FROM notices WHERE attachment_path IS NOT NULL')->fetchColumn();

printf("[%s] Daily report (PHP %s, %s)\n", date('Y-m-d H:i'), PHP_VERSION, PHP_SAPI);
printf("  Notices: %d total, %d with attachments\n", $total, $withFile);
