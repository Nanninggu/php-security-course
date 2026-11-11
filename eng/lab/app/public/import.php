<?php
// Imports the <notice> entries of an XML file as notices (uses SimpleXML).
// A SimpleXML regression has been reported after security patches, so this is part of the post-patch regression check.
require __DIR__ . '/../src/bootstrap.php';

$user = require_login();
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /board.php');
    exit;
}
check_csrf();

$file = $_FILES['xml'] ?? null;
if (!$file || $file['error'] !== UPLOAD_ERR_OK || $file['size'] > MAX_UPLOAD) {
    header('Location: /board.php?msg=error&why=' . urlencode('Could not upload the XML file.'));
    exit;
}

libxml_use_internal_errors(true);
$xml = simplexml_load_file($file['tmp_name'], SimpleXMLElement::class, LIBXML_NONET);
if ($xml === false) {
    header('Location: /board.php?msg=error&why=' . urlencode('The XML format is not valid.'));
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
