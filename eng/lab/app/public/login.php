<?php
require __DIR__ . '/../src/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /index.php');
    exit;
}
check_csrf();

$stmt = db()->prepare('SELECT password_hash FROM users WHERE username = ?');
$stmt->execute([(string)($_POST['username'] ?? '')]);
$row = $stmt->fetch();

if ($row && password_verify((string)($_POST['password'] ?? ''), $row['password_hash'])) {
    session_regenerate_id(true);
    $_SESSION['user'] = (string)$_POST['username'];
    header('Location: /board.php');
    exit;
}
header('Location: /index.php?error=1');
