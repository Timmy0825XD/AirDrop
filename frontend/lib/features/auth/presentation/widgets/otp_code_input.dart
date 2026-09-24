import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  static const _length = 6;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    final focusedBorder = border.copyWith(
      borderSide: BorderSide(color: colors.primary, width: 1.5),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 44,
            height: 56,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              autofocus: index == 0,
              keyboardType: TextInputType.number,
              textInputAction: index == _length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surface,
                contentPadding: EdgeInsets.zero,
                counterText: '',
                border: border,
                enabledBorder: border,
                focusedBorder: focusedBorder,
              ),
              onChanged: (value) => _handleChanged(index, value),
            ),
          ),
        );
      }),
    );
  }

  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      _emitCode();
      return;
    }
    if (digits.length > 1) {
      _fillFrom(index, digits);
    } else {
      _controllers[index].text = digits;
      if (index < _length - 1) _focusNodes[index + 1].requestFocus();
    }
    _emitCode();
  }

  void _fillFrom(int start, String digits) {
    for (var index = start; index < _length; index++) {
      final offset = index - start;
      if (offset < digits.length) {
        _controllers[index].text = digits[offset];
      }
    }
    final nextIndex = start + digits.length >= _length
        ? _length - 1
        : start + digits.length;
    _focusNodes[nextIndex].requestFocus();
  }

  void _emitCode() {
    widget.onChanged(_controllers.map((controller) => controller.text).join());
  }
}
