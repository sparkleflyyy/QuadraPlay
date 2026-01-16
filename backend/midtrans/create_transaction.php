<?php
/**
 * Create Midtrans Transaction
 * Endpoint: POST /midtrans/create_transaction.php
 */

// CORS Headers - MUST be first!
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=UTF-8');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/config.php';

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

try {
    // Get request body
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);
    
    logMidtrans('Create Transaction Request', $input);
    
    if (!$input) {
        jsonResponse(['success' => false, 'message' => 'Invalid JSON input'], 400);
    }
    
    // Validate required fields
    if (empty($input['order_id'])) {
        jsonResponse(['success' => false, 'message' => 'order_id is required'], 400);
    }
    
    if (empty($input['gross_amount']) || $input['gross_amount'] <= 0) {
        jsonResponse(['success' => false, 'message' => 'gross_amount must be greater than 0'], 400);
    }
    
    // Build transaction details
    $transactionDetails = [
        'order_id' => $input['order_id'],
        'gross_amount' => (int) $input['gross_amount']
    ];
    
    // Build customer details
    $customerDetails = [];
    if (!empty($input['customer_details'])) {
        $customerDetails = [
            'first_name' => $input['customer_details']['first_name'] ?? 'Customer',
            'email' => $input['customer_details']['email'] ?? '',
            'phone' => $input['customer_details']['phone'] ?? ''
        ];
    }
    
    // Build item details
    $itemDetails = [];
    if (!empty($input['item_details'])) {
        foreach ($input['item_details'] as $item) {
            $quantity = (int) ($item['quantity'] ?? 1);
            $price = (int) ($item['price'] ?? 0);
            
            // Jika price adalah total dan quantity > 1, hitung harga per unit
            // untuk memastikan price * quantity = gross_amount
            if ($price == 0 && !empty($input['gross_amount'])) {
                $price = $quantity > 0 ? intval($input['gross_amount'] / $quantity) : (int) $input['gross_amount'];
            }
            
            $itemDetails[] = [
                'id' => $item['id'] ?? 'item',
                'price' => $price,
                'quantity' => $quantity,
                'name' => $item['name'] ?? 'Item'
            ];
        }
    } else {
        // Default item if not provided
        $itemDetails[] = [
            'id' => 'rental-ps',
            'price' => (int) $input['gross_amount'],
            'quantity' => 1,
            'name' => 'Rental PlayStation'
        ];
    }
    
    // Build Snap API payload
    $snapPayload = [
        'transaction_details' => $transactionDetails,
        'customer_details' => $customerDetails,
        'item_details' => $itemDetails,
        'callbacks' => [
            'finish' => 'quadraplay://payment/finish',
            'unfinish' => 'quadraplay://payment/unfinish',
            'error' => 'quadraplay://payment/error'
        ]
    ];
    
    logMidtrans('Snap Payload', $snapPayload);
    
    // Call Midtrans Snap API
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => MIDTRANS_SNAP_URL,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($snapPayload),
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
    
    logMidtrans('Midtrans Response', [
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
    
    if ($httpCode >= 200 && $httpCode < 300 && !empty($responseData['token'])) {
        // Success
        jsonResponse([
            'success' => true,
            'snap_token' => $responseData['token'],
            'redirect_url' => $responseData['redirect_url'] ?? null,
            'order_id' => $input['order_id']
        ]);
    } else {
        // Error from Midtrans
        $errorMessage = $responseData['error_messages'][0] ?? 
                       $responseData['message'] ?? 
                       'Failed to create transaction';
        
        jsonResponse([
            'success' => false,
            'message' => $errorMessage,
            'details' => $responseData
        ], $httpCode >= 400 ? $httpCode : 400);
    }
    
} catch (Exception $e) {
    logMidtrans('Exception', ['message' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
    
    jsonResponse([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ], 500);
}
?>
