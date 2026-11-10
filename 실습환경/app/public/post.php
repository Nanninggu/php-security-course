<?php
require __DIR__ . '/../src/bootstrap.php';

$user = require_login();
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /board.php');
    exit;
}
check_csrf();

$title = trim((string)($_POST['title'] ?? ''));
if ($title === '') {
    header('Location: /board.php?msg=error&why=' . urlencode('제목을 입력해 주세요.'));
    exit;
}

$stored = null;
$original = null;
$file = $_FILES['attachment'] ?? null;
if ($file && $file['error'] !== UPLOAD_ERR_NO_FILE) {
    if ($file['error'] !== UPLOAD_ERR_OK || $file['size'] > MAX_UPLOAD) {
        header('Location: /board.php?msg=error&why=' . urlencode('첨부 파일을 올리지 못했습니다.'));
        exit;
    }
    // 저장 이름은 서버가 정한다. 원래 이름은 표시용으로만 쓴다.
    $stored = bin2hex(random_bytes(16));
    if (!move_uploaded_file($file['tmp_name'], UPLOAD_DIR . '/' . $stored)) {
        header('Location: /board.php?msg=error&why=' . urlencode('첨부 파일을 저장하지 못했습니다.'));
        exit;
    }
    $original = mb_substr(basename((string)$file['name']), 0, 100);
}

$stmt = db()->prepare('INSERT INTO notices (title, body, author, attachment_name, attachment_path, created_at)
                       VALUES (?, ?, ?, ?, ?, ?)');
$stmt->execute([$title, (string)($_POST['body'] ?? ''), $user, $original, $stored, date('Y-m-d H:i')]);
header('Location: /board.php?msg=posted');
