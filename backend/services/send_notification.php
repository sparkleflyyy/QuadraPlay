<?php
/**
 * Send Notification Email Endpoint
 * QuadraPlay - PS Rental App
 * 
 * Endpoint: POST /services/send_notification.php
 * 
 * Digunakan untuk mengirim email notifikasi ke user
 * saat pembayaran dikonfirmasi oleh admin
 */

// CORS Headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=UTF-8');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/EmailService.php';

// Log function
function logNotification($message, $data = null) {
    $logFile = __DIR__ . '/logs/notification_' . date('Y-m-d') . '.log';
    $logDir = dirname($logFile);
    
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] $message";
    if ($data) {
        $logEntry .= "\n" . json_encode($data, JSON_PRETTY_PRINT);
    }
    $logEntry .= "\n" . str_repeat('-', 50) . "\n";
    
    file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
}

// Response helper
function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data);
    exit();
}

// Only accept POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

try {
    // Get request body
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);
    
    logNotification('Send Notification Request', $input);
    
    if (!$input) {
        jsonResponse(['success' => false, 'message' => 'Invalid JSON input'], 400);
    }
    
    // Validate required fields
    $requiredFields = ['email', 'type'];
    foreach ($requiredFields as $field) {
        if (empty($input[$field])) {
            jsonResponse(['success' => false, 'message' => "$field is required"], 400);
        }
    }
    
    $email = filter_var($input['email'], FILTER_VALIDATE_EMAIL);
    if (!$email) {
        jsonResponse(['success' => false, 'message' => 'Invalid email format'], 400);
    }
    
    $type = $input['type'];
    $emailService = new EmailService();
    $result = ['success' => false, 'message' => 'Unknown notification type'];
    
    switch ($type) {
        case 'reservation_confirmed':
            // Data yang diperlukan untuk konfirmasi reservasi
            $data = [
                'email' => $email,
                'reservasi_id' => $input['reservasi_id'] ?? '',
                'customer_name' => $input['customer_name'] ?? 'Pelanggan',
                'item_name' => $input['item_name'] ?? 'PlayStation',
                'jumlah_unit' => $input['jumlah_unit'] ?? '1',
                'jumlah_hari' => $input['jumlah_hari'] ?? '1',
                'tgl_mulai' => $input['tgl_mulai'] ?? '-',
                'tgl_selesai' => $input['tgl_selesai'] ?? '-',
                'total_harga' => $input['total_harga'] ?? '0',
                'alamat' => $input['alamat'] ?? '-',
                'no_wa' => $input['no_wa'] ?? '-',
            ];
            
            $result = $emailService->sendReservationConfirmation($data);
            break;
            
        case 'payment_reminder':
            // TODO: Implement payment reminder email
            $result = ['success' => false, 'message' => 'Payment reminder not implemented yet'];
            break;
            
        case 'delivery_notification':
            // TODO: Implement delivery notification email
            $result = ['success' => false, 'message' => 'Delivery notification not implemented yet'];
            break;
            
        default:
            $result = ['success' => false, 'message' => 'Unknown notification type: ' . $type];
    }
    
    logNotification('Send Notification Result', $result);
    
    if ($result['success']) {
        jsonResponse($result);
    } else {
        jsonResponse($result, 500);
    }
    
} catch (Exception $e) {
    logNotification('Exception', ['message' => $e->getMessage()]);
    jsonResponse(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
