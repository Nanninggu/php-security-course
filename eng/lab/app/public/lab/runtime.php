<?php
// Shows information about the PHP that actually handles web requests. (for teaching)
// The nginx config only lets 127.0.0.1 open it. A page like phpinfo() left open to the outside
// tells attackers your version, so delete it when you are done checking.
header('Content-Type: text/plain; charset=utf-8');

// A value fixed with php_admin_value cannot be changed by the application with ini_set(). Check that here.
$before = ini_get('memory_limit');
$changed = @ini_set('memory_limit', '256M');
$after = ini_get('memory_limit');

$lines = [
    'PHP_VERSION' => PHP_VERSION,
    'PHP_SAPI' => PHP_SAPI,
    'PHP_BINARY' => PHP_BINARY === '' ? '(FPM: empty)' : PHP_BINARY,
    'php.ini' => php_ini_loaded_file() ?: '(none)',
    'pid' => (string)getmypid(),
    'memory_limit' => $before,
    'ini_set(memory_limit, 256M)' => $changed === false ? "refused (stays $after)" : "changed ($before -> $after)",
    'post_max_size' => ini_get('post_max_size'),
    'upload_max_filesize' => ini_get('upload_max_filesize'),
    'session.upload_progress.enabled' => ini_get('session.upload_progress.enabled') ? 'On' : 'Off',
];
foreach ($lines as $k => $v) {
    printf("%-34s %s\n", $k, $v);
}
