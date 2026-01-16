<?php
/**
 * Check Midtrans Transaction Status
 * Endpoint: GET /midtrans/check_status.php?order_id=xxx
 * 
 * This endpoint checks the current status of a transaction
 * directly from Midtrans API.
 */

require_once __DIR__ . '/config.php';

setCorsHeaders();

// Accept GET and POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

try {
    // Get order_id from query params or body
    $orderId = $_GET['order_id'] ?? null;
    
    if (!$orderId && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        $orderId = $input['order_id'] ?? null;
    }
    
    if (empty($orderId)) {
        jsonResponse(['success' => false, 'message' => 'order_id is required'], 400);
    }
    
    logMidtrans('Check Status Request', ['order_id' => $orderId]);
    
    // Build Midtrans API URL for status check
    $statusUrl = MIDTRANS_API_URL . '/v2/' . urlencode($orderId) . '/status';
    
    // Call Midtrans API
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $statusUrl,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Accept: application/json',
            'Authorization: ' . getAuthorizationHeader()
        ],
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_TIMEOUT => 30
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    logMidtrans('Status Check Response', [
        'http_code' => $httpCode,
        'response' => $response,
        'curl_error' => $curlError
    ]);
    
    if ($curlError) {
        jsonResponse([
            'success' => false,
            'message' => 'Connection error: ' . $curlError
        ], 500);
    }
    
    $responseData = json_decode($response, true);
    
    if ($httpCode >= 200 && $httpCode < 300 && !empty($responseData['transaction_status'])) {
        jsonResponse([
            'success' => true,
            'data' => [
                'order_id' => $responseData['order_id'] ?? $orderId,
                'transaction_id' => $responseData['transaction_id'] ?? null,
                'transaction_status' => $responseData['transaction_status'],
                'status_code' => $responseData['status_code'] ?? null,
                'status_message' => $responseData['status_message'] ?? null,
                'payment_type' => $responseData['payment_type'] ?? null,
                'gross_amount' => $responseData['gross_amount'] ?? null,
                'fraud_status' => $responseData['fraud_status'] ?? null,
                'settlement_time' => $responseData['settlement_time'] ?? null,
                'expiry_time' => $responseData['expiry_time'] ?? null,
                'va_numbers' => $responseData['va_numbers'] ?? null,
                'payment_code' => $responseData['payment_code'] ?? null,
                'transaction_time' => $responseData['transaction_time'] ?? null
            ]
        ]);
    } else {
        $errorMessage = $responseData['status_message'] ?? 
                       $responseData['message'] ?? 
                       'Transaction not found';
        
        jsonResponse([
            'success' => false,
            'message' => $errorMessage,
            'status_code' => $responseData['status_code'] ?? null
        ], $httpCode >= 400 ? 404 : 400);
    }
    
} catch (Exception $e) {
    logMidtrans('Check Status Exception', [
        'message' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
    
    jsonResponse([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ], 500);
}
?>
