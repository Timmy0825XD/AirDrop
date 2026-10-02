import 'package:flutter/material.dart';

class ResetMatchIcon extends StatelessWidget {
  const ResetMatchIcon({
    super.key,
    required this.password,
    required this.confirm,
  });

  final TextEditingController password;
  final TextEditingController confirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([password, confirm]),
      builder: (context, _) {
        final match = confirm.text.isNotEmpty && confirm.text == password.text;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: match
              ? Padding(
                  key: const ValueKey('match'),
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: colors.tertiary,
                  ),
                )
              : const SizedBox(key: ValueKey('none'), width: 14),
        );
      },
    );
  }
}