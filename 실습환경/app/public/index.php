<?php
require __DIR__ . '/../src/bootstrap.php';

if (current_user() !== null) {
    header('Location: /board.php');
    exit;
}

$error = isset($_GET['error']) ? '<p class="err">아이디 또는 비밀번호가 올바르지 않습니다.</p>' : '';
page('로그인 - 사내 공지 게시판', '<h1>사내 공지 게시판</h1>' . $error . '
<form method="post" action="/login.php">
  <input type="hidden" name="csrf" value="' . h(csrf_token()) . '">
  <label>아이디 <input name="username" autocomplete="username"></label>
  <label>비밀번호 <input name="password" type="password" autocomplete="current-password"></label>
  <button>로그인</button>
</form>');
