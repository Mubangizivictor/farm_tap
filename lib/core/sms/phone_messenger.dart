import 'package:url_launcher/url_launcher.dart';

/// How a message leaves the phone when the farm sends it itself.
enum MessageRoute {
  /// The phone's own SMS app and SIM (the farm's airtime or SMS bundle).
  sms,

  /// WhatsApp click-to-chat (data only, free to send).
  whatsapp,
}

/// Opens the phone's SMS app or WhatsApp with the message already typed, so
/// the user only taps Send. Costs FarmTap nothing and needs no SMS
/// permission (Google Play allows the SMS intent for any app).
class PhoneMessenger {
  const new({this.launch});

  /// Opens a link (tests pass a fake); null uses url_launcher.
  final Future<bool> Function(Uri uri)? launch;

  /// "+256 772 451 908", "0772451908" or "256772451908" → "+256772451908".
  /// Empty when [phone] holds no digits.
  static String international(String phone) {
    final digits = phone.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (phone.trim().startsWith('+')) return '+$digits';
    if (digits.startsWith('256')) return '+$digits';
    if (digits.startsWith('0') && digits.length == 10) return '+256${digits.substring(1)}';
    if (digits.length == 9) return '+256$digits';
    return '+$digits';
  }

  /// The SMS app link. The body is percent-encoded by hand because some SMS
  /// apps show a `+` for each space when it is form-encoded.
  static Uri smsUri(String to, String text) => Uri.parse('sms:${international(to)}?body=${Uri.encodeComponent(text)}');

  /// The WhatsApp click-to-chat link (wa.me wants digits only).
  static Uri whatsappUri(String to, String text) =>
      Uri.parse('https://wa.me/${international(to).replaceAll('+', '')}?text=${Uri.encodeComponent(text)}');

  static Uri uriFor(MessageRoute route, String to, String text) =>
      route == MessageRoute.sms ? smsUri(to, text) : whatsappUri(to, text);

  /// Opens the app for [route]. False when the phone has no app for it
  /// (e.g. WhatsApp is not installed) or [to] has no number.
  Future<bool> open(MessageRoute route, {required String to, required String text}) async {
    if (international(to).isEmpty) return false;
    final uri = uriFor(route, to, text);
    try {
      final launch = this.launch;
      if (launch != null) return await launch(uri);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
