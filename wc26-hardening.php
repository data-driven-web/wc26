<?php
/**
 * Plugin Name: WC26 Hardening (MU)
 * Description: Security and performance hardening for the 2026 World Cup site. Must-use plugin.
 * Author: Data Driven Tech LLC
 * Version: 1.0.0
 */
if (!defined('ABSPATH')) { exit; }

// Disable file editor
if (!defined('DISALLOW_FILE_EDIT')) define('DISALLOW_FILE_EDIT', true);

// Optionally lock file mods on production
if (defined('WP_ENV') && WP_ENV === 'production') {
    if (!defined('AUTOMATIC_UPDATER_DISABLED')) define('AUTOMATIC_UPDATER_DISABLED', true);
    if (!defined('DISALLOW_FILE_MODS')) define('DISALLOW_FILE_MODS', true);
}

// Disable XML-RPC
add_filter('xmlrpc_enabled', '__return_false');

// Remove author archives
add_action('template_redirect', function () {
    if (is_author()) {
        wp_redirect(home_url('/'), 301);
        exit;
    }
});

// Security headers
add_action('send_headers', function () {
    header('X-Frame-Options: SAMEORIGIN');
    header('X-Content-Type-Options: nosniff');
    header('Referrer-Policy: no-referrer-when-downgrade');
    header('Permissions-Policy: geolocation=(), microphone=(), camera=()');
    header('X-XSS-Protection: 0');
});

// Disable REST user enumeration
add_filter('rest_endpoints', function ($endpoints) {
    unset($endpoints['/wp/v2/users']);
    unset($endpoints['/wp/v2/users/(?P<id>[\d]+)']);
    return $endpoints;
});

// Generic login error
add_filter('login_errors', function () { return 'Login failed.'; });
