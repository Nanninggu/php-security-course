<?php
require __DIR__ . '/../src/bootstrap.php';

require_login();
$stmt = db()->prepare('SELECT attachment_name, attachment_path FROM notices WHERE id = ?');
$stmt->execute([(int)($_GET['id'] ?? 0)]);
$row = $stmt->fetch();

if (!$row || !$row['attachment_path'] || !is_file(UPLOAD_DIR . '/' . $row['attachment_path'])) {
    http_response_code(404);
    exit('File not found.');
}
header('Content-Type: application/octet-stream');
header("Content-Disposition: attachment; filename*=UTF-8''" . rawurlencode($row['attachment_name']));
readfile(UPLOAD_DIR . '/' . $row['attachment_path']);
