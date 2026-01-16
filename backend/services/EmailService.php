<?php
/**
 * Email Service Class
 * QuadraPlay - PS Rental App
 * 
 * Menggunakan PHPMailer untuk mengirim email via Gmail SMTP
 */

require_once __DIR__ . '/../config/email_config.php';

// PHPMailer - kita akan menggunakan versi sederhana tanpa Composer
// Jika hosting mendukung Composer, gunakan: composer require phpmailer/phpmailer

class EmailService {
    private $mailer;
    private $lastError = '';
    
    public function __construct() {
        // Cek apakah PHPMailer sudah di-include
        if (!class_exists('PHPMailer\PHPMailer\PHPMailer')) {
            // Jika belum, gunakan versi built-in atau simple mail
            $this->mailer = null;
        }
    }
    
    /**
     * Send email using PHP mail() function with SMTP wrapper
     * Ini adalah versi simple yang tidak memerlukan PHPMailer library
     */
    public function sendEmail($to, $subject, $htmlBody, $plainBody = '') {
        // Gunakan metode SMTP langsung
        return $this->sendViaSMTP($to, $subject, $htmlBody, $plainBody);
    }
    
    /**
     * Send email via SMTP using fsockopen (tanpa library eksternal)
     */
    private function sendViaSMTP($to, $subject, $htmlBody, $plainBody = '') {
        try {
            // Headers
            $headers = [
                'MIME-Version: 1.0',
                'Content-Type: text/html; charset=UTF-8',
                'From: ' . MAIL_FROM_NAME . ' <' . MAIL_FROM_EMAIL . '>',
                'Reply-To: ' . MAIL_FROM_EMAIL,
                'X-Mailer: PHP/' . phpversion()
            ];
            
            // Untuk Gmail SMTP, kita perlu menggunakan stream_socket_client
            $smtp = @fsockopen('ssl://' . SMTP_HOST, 465, $errno, $errstr, 30);
            
            if (!$smtp) {
                // Fallback ke mail() function
                $this->lastError = "SMTP connection failed: $errstr ($errno). Trying mail() function...";
                return $this->sendViaMail($to, $subject, $htmlBody, $headers);
            }
            
            // SMTP conversation
            $response = fgets($smtp, 515);
            if (substr($response, 0, 3) != '220') {
                fclose($smtp);
                return $this->sendViaMail($to, $subject, $htmlBody, $headers);
            }
            
            // EHLO
            fputs($smtp, "EHLO " . SMTP_HOST . "\r\n");
            $this->getSmtpResponse($smtp);
            
            // AUTH LOGIN
            fputs($smtp, "AUTH LOGIN\r\n");
            $this->getSmtpResponse($smtp);
            
            fputs($smtp, base64_encode(SMTP_USERNAME) . "\r\n");
            $this->getSmtpResponse($smtp);
            
            fputs($smtp, base64_encode(SMTP_PASSWORD) . "\r\n");
            $authResponse = $this->getSmtpResponse($smtp);
            
            if (strpos($authResponse, '235') === false) {
                fclose($smtp);
                $this->lastError = "SMTP Authentication failed";
                return ['success' => false, 'message' => $this->lastError];
            }
            
            // MAIL FROM
            fputs($smtp, "MAIL FROM:<" . MAIL_FROM_EMAIL . ">\r\n");
            $this->getSmtpResponse($smtp);
            
            // RCPT TO
            fputs($smtp, "RCPT TO:<" . $to . ">\r\n");
            $this->getSmtpResponse($smtp);
            
            // DATA
            fputs($smtp, "DATA\r\n");
            $this->getSmtpResponse($smtp);
            
            // Message
            $message = "To: $to\r\n";
            $message .= "From: " . MAIL_FROM_NAME . " <" . MAIL_FROM_EMAIL . ">\r\n";
            $message .= "Subject: $subject\r\n";
            $message .= "MIME-Version: 1.0\r\n";
            $message .= "Content-Type: text/html; charset=UTF-8\r\n";
            $message .= "\r\n";
            $message .= $htmlBody;
            $message .= "\r\n.\r\n";
            
            fputs($smtp, $message);
            $this->getSmtpResponse($smtp);
            
            // QUIT
            fputs($smtp, "QUIT\r\n");
            fclose($smtp);
            
            return ['success' => true, 'message' => 'Email berhasil dikirim'];
            
        } catch (Exception $e) {
            $this->lastError = $e->getMessage();
            return ['success' => false, 'message' => $this->lastError];
        }
    }
    
    private function getSmtpResponse($smtp) {
        $response = '';
        while ($str = fgets($smtp, 515)) {
            $response .= $str;
            if (substr($str, 3, 1) == ' ') break;
        }
        return $response;
    }
    
    /**
     * Fallback: Send via mail() function
     */
    private function sendViaMail($to, $subject, $htmlBody, $headers) {
        $headerString = implode("\r\n", $headers);
        
        if (mail($to, $subject, $htmlBody, $headerString)) {
            return ['success' => true, 'message' => 'Email berhasil dikirim via mail()'];
        } else {
            $this->lastError = 'mail() function failed';
            return ['success' => false, 'message' => $this->lastError];
        }
    }
    
    /**
     * Get last error message
     */
    public function getLastError() {
        return $this->lastError;
    }
    
    /**
     * Send Reservation Confirmation Email
     */
    public function sendReservationConfirmation($data) {
        $to = $data['email'];
        $subject = "✅ Reservasi Dikonfirmasi - QuadraPlay #{$data['reservasi_id']}";
        
        $htmlBody = $this->getReservationConfirmationTemplate($data);
        $plainBody = $this->getPlainTextVersion($data);
        
        return $this->sendEmail($to, $subject, $htmlBody, $plainBody);
    }
    
    /**
     * HTML Template for Reservation Confirmation
     */
    private function getReservationConfirmationTemplate($data) {
        $reservasiId = htmlspecialchars($data['reservasi_id'] ?? '-');
        $customerName = htmlspecialchars($data['customer_name'] ?? 'Pelanggan');
        $itemName = htmlspecialchars($data['item_name'] ?? 'PlayStation');
        $jumlahUnit = htmlspecialchars($data['jumlah_unit'] ?? '1');
        $jumlahHari = htmlspecialchars($data['jumlah_hari'] ?? '1');
        $tglMulai = htmlspecialchars($data['tgl_mulai'] ?? '-');
        $tglSelesai = htmlspecialchars($data['tgl_selesai'] ?? '-');
        $totalHarga = htmlspecialchars($data['total_harga'] ?? '0');
        $alamat = htmlspecialchars($data['alamat'] ?? '-');
        $noWA = htmlspecialchars($data['no_wa'] ?? '-');
        
        return <<<HTML
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Konfirmasi Reservasi - QuadraPlay</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f5f5f5;">
        <tr>
            <td align="center" style="padding: 40px 20px;">
                <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
                    
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center;">
                            <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700;">🎮 QuadraPlay</h1>
                            <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0; font-size: 14px;">Your Gaming Partner</p>
                        </td>
                    </tr>
                    
                    <!-- Success Badge -->
                    <tr>
                        <td style="padding: 30px 30px 10px; text-align: center;">
                            <div style="display: inline-block; background-color: #e8f5e9; color: #2e7d32; padding: 12px 24px; border-radius: 50px; font-weight: 600; font-size: 16px;">
                                ✅ Pembayaran Dikonfirmasi
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Greeting -->
                    <tr>
                        <td style="padding: 20px 30px;">
                            <h2 style="color: #333333; margin: 0 0 10px; font-size: 22px;">Halo, {$customerName}! 👋</h2>
                            <p style="color: #666666; margin: 0; font-size: 15px; line-height: 1.6;">
                                Terima kasih telah menggunakan QuadraPlay. Pembayaran reservasi Anda telah kami terima dan dikonfirmasi.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Reservation Details Card -->
                    <tr>
                        <td style="padding: 10px 30px 30px;">
                            <div style="background-color: #f8f9fa; border-radius: 12px; padding: 25px; border: 1px solid #e9ecef;">
                                <h3 style="color: #667eea; margin: 0 0 20px; font-size: 18px; display: flex; align-items: center;">
                                    📋 Detail Reservasi
                                </h3>
                                
                                <table width="100%" cellspacing="0" cellpadding="0" style="font-size: 14px;">
                                    <tr>
                                        <td style="padding: 8px 0; color: #888888; width: 140px;">ID Reservasi</td>
                                        <td style="padding: 8px 0; color: #333333; font-weight: 600;">#{$reservasiId}</td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #888888; border-top: 1px solid #e9ecef;">Item</td>
                                        <td style="padding: 8px 0; color: #333333; font-weight: 600; border-top: 1px solid #e9ecef;">{$itemName}</td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #888888; border-top: 1px solid #e9ecef;">Jumlah Unit</td>
                                        <td style="padding: 8px 0; color: #333333; font-weight: 600; border-top: 1px solid #e9ecef;">{$jumlahUnit} unit</td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #888888; border-top: 1px solid #e9ecef;">Durasi Sewa</td>
                                        <td style="padding: 8px 0; color: #333333; font-weight: 600; border-top: 1px solid #e9ecef;">{$jumlahHari} hari</td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #888888; border-top: 1px solid #e9ecef;">Tanggal Mulai</td>
                                        <td style="padding: 8px 0; color: #333333; font-weight: 600; border-top: 1px solid #e9ecef;">{$tglMulai}</td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #888888; border-top: 1px solid #e9ecef;">Tanggal Selesai</td>
                                        <td style="padding: 8px 0; color: #333333; font-weight: 600; border-top: 1px solid #e9ecef;">{$tglSelesai}</td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #888888; border-top: 1px solid #e9ecef;">Alamat</td>
                                        <td style="padding: 8px 0; color: #333333; font-weight: 600; border-top: 1px solid #e9ecef;">{$alamat}</td>
                                    </tr>
                                    <tr>
                                        <td style="padding: 8px 0; color: #888888; border-top: 1px solid #e9ecef;">No. WhatsApp</td>
                                        <td style="padding: 8px 0; color: #333333; font-weight: 600; border-top: 1px solid #e9ecef;">{$noWA}</td>
                                    </tr>
                                </table>
                                
                                <!-- Total -->
                                <div style="margin-top: 20px; padding-top: 15px; border-top: 2px solid #667eea;">
                                    <table width="100%" cellspacing="0" cellpadding="0">
                                        <tr>
                                            <td style="color: #333333; font-size: 16px; font-weight: 600;">Total Pembayaran</td>
                                            <td style="color: #667eea; font-size: 20px; font-weight: 700; text-align: right;">Rp {$totalHarga}</td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Next Steps -->
                    <tr>
                        <td style="padding: 0 30px 30px;">
                            <div style="background-color: #e3f2fd; border-radius: 12px; padding: 20px; border-left: 4px solid #2196f3;">
                                <h4 style="color: #1976d2; margin: 0 0 10px; font-size: 15px;">📦 Langkah Selanjutnya:</h4>
                                <ol style="color: #555555; margin: 0; padding-left: 20px; font-size: 14px; line-height: 1.8;">
                                    <li>Tim kami akan memproses reservasi Anda</li>
                                    <li>Anda akan dihubungi untuk konfirmasi pengiriman</li>
                                    <li>PlayStation akan diantar ke alamat Anda</li>
                                    <li>Selamat bermain! 🎮</li>
                                </ol>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Contact Info -->
                    <tr>
                        <td style="padding: 0 30px 30px; text-align: center;">
                            <p style="color: #888888; font-size: 13px; margin: 0;">
                                Ada pertanyaan? Hubungi kami di:<br>
                                <strong style="color: #667eea;">📞 08123456789</strong>
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f9fa; padding: 25px 30px; text-align: center; border-top: 1px solid #e9ecef;">
                            <p style="color: #888888; font-size: 12px; margin: 0 0 5px;">
                                © 2025 QuadraPlay. All rights reserved.
                            </p>
                            <p style="color: #aaaaaa; font-size: 11px; margin: 0;">
                                Email ini dikirim secara otomatis. Mohon tidak membalas email ini.
                            </p>
                        </td>
                    </tr>
                    
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
HTML;
    }
    
    /**
     * Plain text version for email clients that don't support HTML
     */
    private function getPlainTextVersion($data) {
        $reservasiId = $data['reservasi_id'] ?? '-';
        $customerName = $data['customer_name'] ?? 'Pelanggan';
        $itemName = $data['item_name'] ?? 'PlayStation';
        $jumlahUnit = $data['jumlah_unit'] ?? '1';
        $jumlahHari = $data['jumlah_hari'] ?? '1';
        $tglMulai = $data['tgl_mulai'] ?? '-';
        $tglSelesai = $data['tgl_selesai'] ?? '-';
        $totalHarga = $data['total_harga'] ?? '0';
        $alamat = $data['alamat'] ?? '-';
        
        return <<<TEXT
🎮 QuadraPlay - Konfirmasi Reservasi

Halo, {$customerName}!

Pembayaran Anda telah dikonfirmasi ✅

📋 Detail Reservasi:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
• ID Reservasi  : #{$reservasiId}
• Item          : {$itemName}
• Jumlah Unit   : {$jumlahUnit} unit
• Durasi Sewa   : {$jumlahHari} hari
• Tanggal Mulai : {$tglMulai}
• Tanggal Selesai: {$tglSelesai}
• Alamat        : {$alamat}
• Total Bayar   : Rp {$totalHarga}
━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Langkah Selanjutnya:
1. Tim kami akan memproses reservasi Anda
2. Anda akan dihubungi untuk konfirmasi pengiriman
3. PlayStation akan diantar ke alamat Anda
4. Selamat bermain! 🎮

Ada pertanyaan? Hubungi kami di: 08123456789

━━━━━━━━━━━━━━━━━━━━━━━━━━━
QuadraPlay - Your Gaming Partner
© 2025 QuadraPlay
TEXT;
    }
}
