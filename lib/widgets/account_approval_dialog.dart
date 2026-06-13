import 'package:flutter/material.dart';

import '../models/app_user.dart';

Future<void> showAccountApprovalDialog(BuildContext context, AppUser user) {
  final isPaymentDue = user.approvalStatus == 'payment';
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(isPaymentDue ? 'Payment due' : 'Account pending'),
        content: Text(
          isPaymentDue
              ? 'Payment is due. Please make payment to proceed.'
              : 'Your account has already been created but is not active. '
                    'Please contact the admin.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}
