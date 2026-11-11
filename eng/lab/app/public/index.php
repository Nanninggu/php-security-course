<?php
require __DIR__ . '/../src/bootstrap.php';

if (current_user() !== null) {
    header('Location: /board.php');
    exit;
}

$error = isset($_GET['error']) ? '<p class="err">Incorrect username or password.</p>' : '';
page('Sign in - Company Notice Board', '<h1>Company Notice Board</h1>' . $error . '
<form method="post" action="/login.php">
  <input type="hidden" name="csrf" value="' . h(csrf_token()) . '">
  <label>Username <input name="username" autocomplete="username"></label>
  <label>Password <input name="password" type="password" autocomplete="current-password"></label>
  <button>Sign in</button>
</form>');
