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
    header('Location: /board.php?msg=error&why=' . urlencode('Please enter a title.'));
    exit;
}

$stored = null;
$original = null;
$file = $_FILES['attachment'] ?? null;
if ($file && $file['error'] !== UPLOAD_ERR_NO_FILE) {
    if ($file['error'] !== UPLOAD_ERR_OK || $file['size'] > MAX_UPLOAD) {
        header('Location: /board.php?msg=error&why=' . urlencode('Could not upload the attachment.'));
        exit;
    }
    // The server picks the stored name. The original name is used for display only.
    $stored = bin2hex(random_bytes(16));
    if (!move_uploaded_file($file['tmp_name'], UPLOAD_DIR . '/' . $stored)) {
        header('Location: /board.php?msg=error&why=' . urlencode('Could not save the attachment.'));
        exit;
    }
    $original = mb_substr(basename((string)$file['name']), 0, 100);
}

$stmt = db()->prepare('INSERT INTO notices (title, body, author, attachment_name, attachment_path, created_at)
                       VALUES (?, ?, ?, ?, ?, ?)');
$stmt->execute([$title, (string)($_POST['body'] ?? ''), $user, $original, $stored, date('Y-m-d H:i')]);
header('Location: /board.php?msg=posted');
