<?php
// 사내 공지 게시판 (교육용 샘플 서비스)
// 로그인 · 세션 · 파일 업로드 · DB(SQLite) · XML 가져오기 · CLI 배치를 갖춘 작은 서비스.
// 패치 후 "서비스가 그대로 동작하는가"를 확인하는 대상이다.
declare(strict_types=1);

const DB_PATH = '/var/lib/lab/board.sqlite';
const UPLOAD_DIR = '/var/www/app/storage/uploads';   // 웹 루트 밖: 올린 파일이 실행되지 않는다
const MAX_UPLOAD = 5 * 1024 * 1024;

function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO('sqlite:' . DB_PATH, null, null, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    }
    return $pdo;
}

function start_session(): void
{
    if (session_status() !== PHP_SESSION_ACTIVE) {
        session_start(['cookie_httponly' => true, 'cookie_samesite' => 'Lax']);
    }
}

function current_user(): ?string
{
    start_session();
    return $_SESSION['user'] ?? null;
}

function require_login(): string
{
    $user = current_user();
    if ($user === null) {
        header('Location: /index.php');
        exit;
    }
    return $user;
}

function csrf_token(): string
{
    start_session();
    return $_SESSION['csrf'] ??= bin2hex(random_bytes(16));
}

function check_csrf(): void
{
    if (!hash_equals(csrf_token(), (string)($_POST['csrf'] ?? ''))) {
        http_response_code(400);
        exit('잘못된 요청입니다.');
    }
}

function h(?string $s): string
{
    return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8');
}

function page(string $title, string $body): void
{
    echo '<!doctype html><html lang="ko"><head><meta charset="utf-8">'
        . '<meta name="viewport" content="width=device-width, initial-scale=1">'
        . '<title>' . h($title) . '</title>'
        . '<style>body{font-family:system-ui,sans-serif;max-width:760px;margin:40px auto;padding:0 16px;line-height:1.6}'
        . 'table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid #ddd;padding:6px;text-align:left}'
        . 'form{margin:16px 0;padding:12px;border:1px solid #ddd;border-radius:6px}input,textarea{display:block;margin:6px 0;width:100%}'
        . 'button{width:auto}.ok{color:#17803d}.err{color:#b42318}</style></head><body>'
        . $body . '</body></html>';
}
