<?php
/**
 * Unfinish Redirect Handler
 * Redirect user back to app when payment is pending/unfinished
 */

$orderId = $_GET['order_id'] ?? '';
$statusCode = $_GET['status_code'] ?? '';
$transactionStatus = $_GET['transaction_status'] ?? 'pending';

// Log
$logFile = __DIR__ . '/logs/redirect_' . date('Y-m-d') . '.log';
$logData = date('Y-m-d H:i:s') . " - UNFINISH - Order: $orderId, Status: $transactionStatus\n";
@file_put_contents($logFile, $logData, FILE_APPEND);

$deepLink = "quadraplay://payment/unfinish?order_id=" . urlencode($orderId) . 
            "&status=" . urlencode($transactionStatus);
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Menunggu Pembayaran - QuadraPlay</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .card {
            background: white;
            border-radius: 20px;
            padding: 40px;
            text-align: center;
            max-width: 400px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .icon {
            width: 80px;
            height: 80px;
            background: #FFA726;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        .icon svg { width: 40px; height: 40px; fill: white; }
        h1 { color: #333; margin-bottom: 10px; font-size: 24px; }
        p { color: #666; margin-bottom: 20px; }
        .order-id { 
            background: #f5f5f5; 
            padding: 10px 20px; 
            border-radius: 10px; 
            font-family: monospace;
            margin-bottom: 20px;
        }
        .btn {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 40px;
            border-radius: 30px;
            text-decoration: none;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">
            <svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
        </div>
        <h1>Menunggu Pembayaran</h1>
        <p>Silakan selesaikan pembayaran Anda sebelum waktu habis.</p>
        <div class="order-id">Order ID: <?= htmlspecialchars($orderId) ?></div>
        <a href="<?= $deepLink ?>" class="btn">Kembali ke Aplikasi</a>
    </div>
    
    <script>
        setTimeout(function() {
            window.location.href = "<?= $deepLink ?>";
        }, 2000);
    </script>
</body>
</html>
