import 'package:url_launcher/url_launcher.dart';

Future<bool> openWhatsApp({
  required String? phone,
  String body = '',
}) async {
  if (phone == null || phone.trim().isEmpty) return false;
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) {
    digits = '962${digits.substring(1)}';
  }
  if (digits.isEmpty) return false;
  final appUri = Uri.parse(
    'whatsapp://send?phone=$digits&text=${Uri.encodeComponent(body)}',
  );
  final webUri = Uri.parse(
    'https://wa.me/$digits?text=${Uri.encodeComponent(body)}',
  );

  try {
    if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
      return true;
    }
  } catch (_) {
    // Fall back to web URL when WhatsApp app is unavailable.
  }

  try {
    return await launchUrl(webUri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
