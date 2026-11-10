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
    'posted' => '<p class="ok">공지를 등록했습니다.</p>',
    'imported' => '<p class="ok">XML에서 공지 ' . (int)($_GET['n'] ?? 0) . '건을 가져왔습니다.</p>',
    'error' => '<p class="err">' . h($_GET['why'] ?? '처리하지 못했습니다.') . '</p>',
    default => '',
};
$csrf = h(csrf_token());

page('공지 목록 - 사내 공지 게시판', '<h1>공지 목록</h1>
<p>' . h($user) . '님으로 로그인했습니다. <a href="/logout.php">로그아웃</a></p>' . $msg . '
<table><tr><th>번호</th><th>제목</th><th>작성자</th><th>첨부</th><th>작성일</th></tr>' . $list . '</table>
<form method="post" action="/post.php" enctype="multipart/form-data">
  <h2>새 공지</h2>
  <input type="hidden" name="csrf" value="' . $csrf . '">
  <label>제목 <input name="title" required></label>
  <label>내용 <textarea name="body" rows="3"></textarea></label>
  <label>첨부 파일 (5MB 이하) <input type="file" name="attachment"></label>
  <button>등록</button>
</form>
<form method="post" action="/import.php" enctype="multipart/form-data">
  <h2>XML로 공지 가져오기</h2>
  <input type="hidden" name="csrf" value="' . $csrf . '">
  <input type="file" name="xml" accept=".xml" required>
  <button>가져오기</button>
</form>');
