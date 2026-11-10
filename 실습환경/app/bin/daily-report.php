<?php
// 매일 새벽 cron으로 돌리는 배치 작업 (예: 0 4 * * * php /var/www/app/bin/daily-report.php)
// 명령줄에서 `php`로 실행되므로, 웹 요청과 다른 PHP로 돌아갈 수 있다.
require __DIR__ . '/../src/bootstrap.php';

$total = (int)db()->query('SELECT COUNT(*) FROM notices')->fetchColumn();
$withFile = (int)db()->query('SELECT COUNT(*) FROM notices WHERE attachment_path IS NOT NULL')->fetchColumn();

printf("[%s] 일일 리포트 (PHP %s, %s)\n", date('Y-m-d H:i'), PHP_VERSION, PHP_SAPI);
printf("  전체 공지 %d건, 첨부 있는 공지 %d건\n", $total, $withFile);
