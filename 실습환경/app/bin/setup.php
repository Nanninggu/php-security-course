<?php
// 샘플 서비스 DB를 만든다. 실습 서버가 처음 켜질 때 한 번 실행된다.
require __DIR__ . '/../src/bootstrap.php';

db()->exec('CREATE TABLE IF NOT EXISTS users (username TEXT PRIMARY KEY, password_hash TEXT NOT NULL)');
db()->exec('CREATE TABLE IF NOT EXISTS notices (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT, author TEXT NOT NULL,
    attachment_name TEXT, attachment_path TEXT, created_at TEXT NOT NULL)');

$stmt = db()->prepare('INSERT OR IGNORE INTO users (username, password_hash) VALUES (?, ?)');
$stmt->execute(['admin', password_hash('lab-password-1234', PASSWORD_DEFAULT)]);

$count = (int)db()->query('SELECT COUNT(*) FROM notices')->fetchColumn();
if ($count === 0) {
    $stmt = db()->prepare('INSERT INTO notices (title, body, author, created_at) VALUES (?, ?, ?, ?)');
    $stmt->execute(['11월 정기 점검 안내', '매월 셋째 주 토요일 새벽에 정기 점검이 있습니다.', 'admin', date('Y-m-d H:i')]);
    $stmt->execute(['보안 업데이트 공지', 'PHP 보안 업데이트를 진행할 예정입니다.', 'admin', date('Y-m-d H:i')]);
}
echo "샘플 DB 준비 완료: " . DB_PATH . PHP_EOL;
