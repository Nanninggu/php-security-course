<?php
require __DIR__ . '/../src/bootstrap.php';

$user = require_login();
$rows = db()->query('SELECT id, title, author, attachment_name, created_at FROM notices ORDER BY id DESC')->fetchAll();

$list = '';
foreach ($rows as $r) {
    $file = $r['attachment_name'] ? '<a href="/download.php?id=' . (int)$r['id'] . '">' . h($r['attachment_name']) . '</a>' : '';
    $list .= '<tr><td>' . (int)$r['id'] . '</td><td>' . h($r['title']) . '</td><td>' . h($r['author'])
        . '</td><td>' . $file . '</td><td>' . h($r['created_at']) . '</td></tr>';
}
$msg = match ($_GET['msg'] ?? '') {
    'posted' => '<p class="ok">Notice posted.</p>',
    'imported' => '<p class="ok">Imported ' . (int)($_GET['n'] ?? 0) . ' notices from XML.</p>',
    'error' => '<p class="err">' . h($_GET['why'] ?? 'Could not process the request.') . '</p>',
    default => '',
};
$csrf = h(csrf_token());

page('Notices - Company Notice Board', '<h1>Notices</h1>
<p>' . h($user) . ' is signed in. <a href="/logout.php">Sign out</a></p>' . $msg . '
<table><tr><th>No.</th><th>Title</th><th>Author</th><th>Attachment</th><th>Posted</th></tr>' . $list . '</table>
<form method="post" action="/post.php" enctype="multipart/form-data">
  <h2>New notice</h2>
  <input type="hidden" name="csrf" value="' . $csrf . '">
  <label>Title <input name="title" required></label>
  <label>Body <textarea name="body" rows="3"></textarea></label>
  <label>Attachment (up to 5 MB) <input type="file" name="attachment"></label>
  <button>Post</button>
</form>
<form method="post" action="/import.php" enctype="multipart/form-data">
  <h2>Import notices from XML</h2>
  <input type="hidden" name="csrf" value="' . $csrf . '">
  <input type="file" name="xml" accept=".xml" required>
  <button>Import</button>
</form>');
