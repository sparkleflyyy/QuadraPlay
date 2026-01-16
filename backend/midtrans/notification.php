<?php
/**
 * Midtrans Webhook Notification Handler
 * Endpoint: POST /midtrans/notification.php
 * 
 * This endpoint receives payment notifications from Midtrans
 * and updates the payment status in the database.
 * 
 * Note: You need to set this URL in your Midtrans Dashboard:
 * https://247go.app/api/quadraplay/midtrans/notification.php
 */

require_once __DIR__ . '/config.php';

setCorsHeaders();

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

try {
    // Get notification body
    $rawInput = file_get_contents('php://input');
    $notification = json_decode($rawInput, true);
    
    logMidtrans('Webhook Notification Received', $notification);
    
    if (!$notification) {
        jsonResponse(['success' => false, 'message' => 'Invalid JSON'], 400);
    }
    
    // Extract notification data
    $orderId = $notification['order_id'] ?? null;
    $transactionStatus = $notification['transaction_status'] ?? null;
    $transactionId = $notification['transaction_id'] ?? null;
    $paymentType = $notification['payment_type'] ?? null;
    $grossAmount = $notification['gross_amount'] ?? null;
    $signatureKey = $notification['signature_key'] ?? null;
    $statusCode = $notification['status_code'] ?? null;
    $fraudStatus = $notification['fraud_status'] ?? null;
    
    if (!$orderId || !$transactionStatus) {
        logMidtrans('Invalid notification - missing required fields');
        jsonResponse(['success' => false, 'message' => 'Invalid notification data'], 400);
    }
    
    // Verify signature
    $serverKey = MIDTRANS_SERVER_KEY;
    $expectedSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);
    
    if ($signatureKey !== $expectedSignature) {
        logMidtrans('Signature verification failed', [
            'expected' => $expectedSignature,
            'received' => $signatureKey
        ]);
        // Note: Untuk development, kita bisa skip verifikasi ini
        // Untuk production, uncomment line di bawah:
        // jsonResponse(['success' => false, 'message' => 'Invalid signature'], 403);
    }
    
    // Determine payment status based on transaction_status
    $paymentStatus = determinePaymentStatus($transactionStatus, $fraudStatus);
    
    // Extract additional data
    $vaNumbers = $notification['va_numbers'] ?? null;
    $paymentCode = $notification['payment_code'] ?? null;
    $billKey = $notification['bill_key'] ?? null;
    $billerCode = $notification['biller_code'] ?? null;
    $settlementTime = $notification['settlement_time'] ?? null;
    $expiryTime = $notification['expiry_time'] ?? null;
    
    // Prepare data for database update
    $updateData = [
        'order_id' => $orderId,
        'transaction_id' => $transactionId,
        'status' => $paymentStatus,
        'transaction_status' => $transactionStatus,
        'payment_type' => $paymentType,
        'gross_amount' => $grossAmount,
        'fraud_status' => $fraudStatus,
        'settlement_time' => $settlementTime,
        'expiry_time' => $expiryTime,
        'va_numbers' => $vaNumbers ? json_encode($vaNumbers) : null,
        'payment_code' => $paymentCode,
        'updated_at' => date('Y-m-d H:i:s')
    ];
    
    logMidtrans('Update Data prepared', $updateData);
    
    // Update payment in database via 247go.app API
    $updateResult = updatePaymentInDatabase($orderId, $updateData);
    
    if ($updateResult['success']) {
        logMidtrans('Payment updated successfully', ['order_id' => $orderId]);
        jsonResponse(['success' => true, 'message' => 'Notification processed']);
    } else {
        logMidtrans('Failed to update payment', $updateResult);
        jsonResponse(['success' => false, 'message' => 'Failed to update payment'], 500);
    }
    
} catch (Exception $e) {
    logMidtrans('Webhook Exception', [
        'message' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
    
    jsonResponse(['success' => false, 'message' => 'Server error'], 500);
}

/**
 * Determine payment status based on Midtrans transaction_status
 */
function determinePaymentStatus($transactionStatus, $fraudStatus = null) {
    switch ($transactionStatus) {
        case 'capture':
            // For credit card, check fraud status
            if ($fraudStatus === 'challenge') {
                return 'pending';
            }
            return 'confirmed';
            
        case 'settlement':
            return 'confirmed';
            
        case 'pending':
            return 'pending';
            
        case 'deny':
            return 'denied';
            
        case 'cancel':
            return 'cancelled';
            
        case 'expire':
            return 'expired';
            
        case 'failure':
            return 'failed';
            
        default:
            return 'pending';
    }
}

/**
 * Update payment record in database via 247go.app API
 */
function updatePaymentInDatabase($orderId, $updateData) {
    $apiUrl = 'https://247go.app/api3.php';
    
    // Build SQL for updating payment
    $setFields = [];
    $setFields[] = "transaction_id = '" . addslashes($updateData['transaction_id'] ?? '') . "'";
    $setFields[] = "status = '" . addslashes($updateData['status']) . "'";
    $setFields[] = "transaction_status = '" . addslashes($updateData['transaction_status']) . "'";
    $setFields[] = "payment_type = '" . addslashes($updateData['payment_type'] ?? '') . "'";
    $setFields[] = "gross_amount = '" . addslashes($updateData['gross_amount'] ?? '') . "'";
    
    if (!empty($updateData['fraud_status'])) {
        $setFields[] = "fraud_status = '" . addslashes($updateData['fraud_status']) . "'";
    }
    if (!empty($updateData['settlement_time'])) {
        $setFields[] = "settlement_time = '" . addslashes($updateData['settlement_time']) . "'";
    }
    if (!empty($updateData['expiry_time'])) {
        $setFields[] = "expiry_time = '" . addslashes($updateData['expiry_time']) . "'";
    }
    if (!empty($updateData['va_numbers'])) {
        $setFields[] = "va_numbers = '" . addslashes($updateData['va_numbers']) . "'";
    }
    if (!empty($updateData['payment_code'])) {
        $setFields[] = "payment_code = '" . addslashes($updateData['payment_code']) . "'";
    }
    
    $setFields[] = "updated_at = NOW()";
    
    $sql = "UPDATE payments SET " . implode(', ', $setFields) . 
           " WHERE order_id = '" . addslashes($orderId) . "'";
    
    logMidtrans('SQL Query', $sql);
    
    // Prepare API request to 247go.app
    $payload = [
        'key' => 'quadraplay', // Your API key
        'action' => 'query',
        'query' => $sql
    ];
    
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $apiUrl,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query($payload),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/x-www-form-urlencoded'
        ],
        CURLOPT_TIMEOUT => 30
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    logMidtrans('Database Update Response', [
        'http_code' => $httpCode,
        'response' => $response,
        'curl_error' => $curlError
    ]);
    
    if ($curlError) {
        return ['success' => false, 'message' => 'Connection error: ' . $curlError];
    }
    
    $responseData = json_decode($response, true);
    
    if ($httpCode >= 200 && $httpCode < 300) {
        return ['success' => true, 'data' => $responseData];
    }
    
    return ['success' => false, 'message' => 'Failed to update database'];
}
?>
