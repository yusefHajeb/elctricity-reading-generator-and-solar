import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showDeveloperInfoDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('معلومات المطور : '),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeveloperInfoRow(
              name: 'عمار الشميري',
              phone: '777889417',
              context: context,
            ),
            _buildDeveloperInfoRow(
              name: 'يوسف حاجب',
              phone: '771274299',
              context: context,
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildDeveloperInfoRow({
  required String name,
  required String phone,
  required BuildContext context,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      const Icon(Icons.person),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              // style: const TextStyle(
              //   fontWeight: FontWeight.bold,
              //   fontSize: 14,
              // ),
            ),
            Text(
              phone,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      // Spacer(),
      Wrap(
        spacing: 1,
        children: [
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.whatsapp,
              color: Colors.greenAccent,
            ),
            onPressed: () =>
                _launchUrl('whatsapp://send?phone=$phone', context),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.blueAccent),
            onPressed: () => _launchUrl('tel:$phone', context),
          ),
        ],
      ),
    ],
  );
}

Future<void> _launchUrl(String url, BuildContext context) async {
  if (!context.mounted) return;
  try {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot launch $url'),
      ),
    );
  }
}
