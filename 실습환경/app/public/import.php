<?php
// XML 파일의 <notice> 항목을 공지로 가져온다 (SimpleXML 사용).
// 보안 패치 뒤 SimpleXML 관련 회귀가 보고된 적이 있어, 패치 후 회귀 점검 대상에 넣는다.
require __DIR__ . '/../src/bootstrap.php';

$user = require_login();
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /board.php');
    exit;
}
check_csrf();

$file = $_FILES['xml'] ?? null;
if (!$file || $file['error'] !== UPLOAD_ERR_OK || $file['size'] > MAX_UPLOAD) {
    header('Location: /board.php?msg=error&why=' . urlencode('XML 파일을 올리지 못했습니다.'));
    exit;
}

libxml_use_internal_errors(true);
$xml = simplexml_load_file($file['tmp_name'], SimpleXMLElement::class, LIBXML_NONET);
if ($xml === false) {
    header('Location: /board.php?msg=error&why=' . urlencode('XML 형식이 올바르지 않습니다.'));
    exit;
}

$stmt = db()->prepare('INSERT INTO notices (title, body, author, created_at) VALUES (?, ?, ?, ?)');
$count = 0;
foreach ($xml->notice as $notice) {
    $title = trim((string)$notice->title);
    if ($title === '') {
        continue;
    }
    $stmt->execute([$title, trim((string)$notice->body), $user . ' (XML)', date('Y-m-d H:i')]);
    $count++;
}
header('Location: /board.php?msg=imported&n=' . $count);
