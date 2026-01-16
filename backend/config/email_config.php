<?php
/**
 * Email Configuration
 * QuadraPlay - PS Rental App
 * 
 * Menggunakan Gmail SMTP dengan PHPMailer
 */

// Gmail SMTP Configuration
define('SMTP_HOST', 'smtp.gmail.com');
define('SMTP_PORT', 587);
define('SMTP_SECURE', 'tls'); // tls atau ssl

// Gmail Credentials
// PENTING: Gunakan App Password, bukan password biasa!
// Cara mendapatkan App Password:
// 1. Buka https://myaccount.google.com/security
// 2. Aktifkan 2-Step Verification
// 3. Buka App Passwords
// 4. Generate password untuk "Mail"
define('SMTP_USERNAME', 'your-email@gmail.com'); // Ganti dengan email Gmail Anda
define('SMTP_PASSWORD', 'your-app-password');     // Ganti dengan App Password dari Google

// Sender Information
define('MAIL_FROM_EMAIL', 'your-email@gmail.com'); // Sama dengan SMTP_USERNAME
define('MAIL_FROM_NAME', 'QuadraPlay');

// Company Information (untuk template email)
define('COMPANY_NAME', 'QuadraPlay');
define('COMPANY_ADDRESS', 'Jl. Contoh Alamat No. 123, Kota Anda');
define('COMPANY_PHONE', '08123456789');
define('COMPANY_WEBSITE', 'https://quadraplay.com');

// Debug mode (set false untuk production)
define('SMTP_DEBUG', 0); // 0 = off, 1 = client messages, 2 = client and server messages
