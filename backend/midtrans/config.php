<?php
/**
 * Midtrans Configuration
 * QuadraPlay - PS Rental App
 * 
 * Environment: SANDBOX (for testing)
 */

// Midtrans Credentials
define('MIDTRANS_MERCHANT_ID', 'G435251730');
define('MIDTRANS_CLIENT_KEY', 'Mid-client-DVAMVogPvIprVqdb');
define('MIDTRANS_SERVER_KEY', 'Mid-server-3qgT8saiYzGrj5nZu5cdpmhd');

// Environment (sandbox/production)
define('MIDTRANS_IS_PRODUCTION', false);

// Midtrans API URLs
if (MIDTRANS_IS_PRODUCTION) {
    define('MIDTRANS_SNAP_URL', 'https://app.midtrans.com/snap/v1/transactions');
    define('MIDTRANS_API_URL', 'https://api.midtrans.com');
} else {
    define('MIDTRANS_SNAP_URL', 'https://app.sandbox.midtrans.com/snap/v1/transactions');
    define('MIDTRANS_API_URL', 'https://api.sandbox.midtrans.com');
}

// Helper function to get authorization header
function getAuthorizationHeader() {
    return 'Basic ' . base64_encode(MIDTRANS_SERVER_KEY . ':');
}

// CORS Headers
function setCorsHeaders() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Content-Type: application/json');
    
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }
}

// JSON Response helper
function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data);
    exit();
}

// Logging helper
function logMidtrans($message, $data = null) {
    $logFile = __DIR__ . '/logs/midtrans_' . date('Y-m-d') . '.log';
    $logDir = dirname($logFile);
    
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] $message";
    
    if ($data !== null) {
        $logMessage .= "\n" . json_encode($data, JSON_PRETTY_PRINT);
    }
    
    $logMessage .= "\n" . str_repeat('-', 50) . "\n";
    
    file_put_contents($logFile, $logMessage, FILE_APPEND);
}
?>
