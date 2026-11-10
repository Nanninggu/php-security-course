<?php
// 웹 요청을 실제로 처리하는 PHP의 정보를 보여 준다. (교육용)
// nginx 설정에서 127.0.0.1만 열 수 있게 막아 두었다. 운영 서버에서 phpinfo() 같은 페이지를
// 외부에 열어 두면 공격자에게 버전 정보를 알려 주게 되므로, 확인이 끝나면 지운다.
header('Content-Type: text/plain; charset=utf-8');

// php_admin_value로 고정한 값은 애플리케이션이 ini_set()으로 바꿀 수 없다. 그걸 확인해 본다.
$before = ini_get('memory_limit');
$changed = @ini_set('memory_limit', '256M');
$after = ini_get('memory_limit');

$lines = [
    'PHP_VERSION' => PHP_VERSION,
    'PHP_SAPI' => PHP_SAPI,
    'PHP_BINARY' => PHP_BINARY === '' ? '(FPM: 비어 있음)' : PHP_BINARY,
    'php.ini' => php_ini_loaded_file() ?: '(없음)',
    'pid' => (string)getmypid(),
    'memory_limit' => $before,
    'ini_set(memory_limit, 256M)' => $changed === false ? "거부됨 ($after 유지)" : "바뀜 ($before → $after)",
    'post_max_size' => ini_get('post_max_size'),
    'upload_max_filesize' => ini_get('upload_max_filesize'),
    'session.upload_progress.enabled' => ini_get('session.upload_progress.enabled') ? 'On' : 'Off',
];
foreach ($lines as $k => $v) {
    printf("%-34s %s\n", $k, $v);
}
