<?php
// Creates the sample service database. Runs once when the lab server first starts.
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
    $stmt->execute(['November regular maintenance', 'Regular maintenance runs early on the third Saturday of every month.', 'admin', date('Y-m-d H:i')]);
    $stmt->execute(['Security update notice', 'We plan to apply the PHP security update.', 'admin', date('Y-m-d H:i')]);
}
echo "Sample DB ready: " . DB_PATH . PHP_EOL;
