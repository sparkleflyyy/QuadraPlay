<?php
/**
 * Error Redirect Handler
 * Redirect user back to app when payment fails
 */

$orderId = $_GET['order_id'] ?? '';
$statusCode = $_GET['status_code'] ?? '';
$transactionStatus = $_GET['transaction_status'] ?? 'error';

// Log
$logFile = __DIR__ . '/logs/redirect_' . date('Y-m-d') . '.log';
$logData = date('Y-m-d H:i:s') . " - ERROR - Order: $orderId, Status: $transactionStatus\n";
@file_put_contents($logFile, $logData, FILE_APPEND);

$deepLink = "quadraplay://payment/error?order_id=" . urlencode($orderId) . 
            "&status=" . urlencode($transactionStatus);
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pembayaran Gagal - QuadraPlay</title>
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
            background: #F44336;
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
            <svg viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>
        </div>
        <h1>Pembayaran Gagal</h1>
        <p>Maaf, terjadi kesalahan saat memproses pembayaran Anda. Silakan coba lagi.</p>
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
