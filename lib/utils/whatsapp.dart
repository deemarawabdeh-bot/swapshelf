import 'package:url_launcher/url_launcher.dart';

Future<bool> openWhatsApp({
  required String? phone,
  String body = '',
}) async {
  if (phone == null || phone.trim().isEmpty) return false;
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;
  final uri = Uri.parse(
    'https://wa.me/$digits?text=${Uri.encodeComponent(body)}',
  );
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
