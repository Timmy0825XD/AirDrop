import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpBoxesInput extends StatefulWidget {
  const OtpBoxesInput({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<OtpBoxesInput> createState() => _OtpBoxesInputState();
}

class _OtpBoxesInputState extends State<OtpBoxesInput> {
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 336),
      child: Row(
        children: List.generate(_length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _OtpCell(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                autofocus: index == 0,
                isLast: index == _length - 1,
                onChanged: (value) => _handleChanged(index, value),
              ),
            ),
          );
        }),
      ),
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

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.isLast,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final bool isLast;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final filled = controller.text.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 56,
          decoration: _decoration(colors, focused, filled),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildDot(colors, focused, filled),
              _buildField(context),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _decoration(ColorScheme colors, bool focused, bool filled) {
    final base = colors.onSurface.withValues(alpha: filled ? 0.1 : 0.04);
    return BoxDecoration(
      color: focused
          ? Color.alphaBlend(colors.primary.withValues(alpha: 0.12), base)
          : base,
      borderRadius: BorderRadius.circular(14),
      border: focused
          ? Border.all(color: colors.primary.withValues(alpha: 0.6))
          : null,
      boxShadow: focused
          ? [BoxShadow(color: colors.primary.withValues(alpha: 0.35), blurRadius: 18)]
          : null,
    );
  }

  Widget _buildDot(ColorScheme colors, bool focused, bool filled) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: filled ? 0 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: focused ? 8 : 6,
        height: focused ? 8 : 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: focused
              ? colors.primary
              : colors.onSurface.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      showCursor: false,
      keyboardType: TextInputType.number,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      textAlign: TextAlign.center,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        filled: false,
        counterText: '',
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onChanged: onChanged,
    );
  }
}