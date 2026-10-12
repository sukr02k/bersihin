class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Bersihin';
  static const String appVersion = '1.1.0';
  static const String appDescription =
      'Aplikasi Kasir & Manajemen Laundry Modern - 100% Offline';

  // Database
  static const String databaseName = 'laundryfull.db';
  static const int databaseVersion = 4;

  // Invoice
  static const String defaultInvoicePrefix = 'BRSH';
  static const int invoiceNumberLength = 4;

  // Default Values
  static const int defaultServiceDuration = 3; // days
  static const String defaultPaymentMethod = 'cash';

  // Pagination
  static const int defaultPageSize = 20;
  static const int recentOrdersLimit = 5;

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy HH:mm';
  static const String dateFormatShort = 'dd/MM/yy';
  static const String timeFormat = 'HH:mm';
  static const String invoiceDateFormat = 'yyMMdd';

  // Printer
  static const int printerPaperWidth = 58; // mm
  static const int printerCharPerLine = 32;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;

  // Default Admin Credentials
  static const String defaultOwnerUsername = 'owner';
  static const String defaultOwnerPassword = 'admin123';
  static const String defaultOwnerName = 'Owner Bersihin';

  // Settings Keys
  static const String keyLaundryName = 'laundry_name';
  static const String keyLaundryAddress = 'laundry_address';
  static const String keyLaundryPhone = 'laundry_phone';
  static const String keyInvoicePrefix = 'invoice_prefix';
  static const String keyReceiptFooter = 'receipt_footer';
  static const String keyPrinterAddress = 'printer_address';
  static const String keyLastInvoiceDate = 'last_invoice_date';
  static const String keyLastInvoiceNumber = 'last_invoice_number';

  // Default Laundry Info
  static const String defaultLaundryName = 'Bersihin Laundry';
  static const String defaultLaundryAddress = 'Jl. Merdeka No. 10, Indonesia';
  static const String defaultLaundryPhone = '6281234567890';
  static const String defaultReceiptFooter =
      'Terima kasih atas kepercayaan Anda. Simpan struk ini sebagai bukti pengambilan.';
}
