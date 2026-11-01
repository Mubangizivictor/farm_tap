import 'package:flutter/material.dart';

class BigNumberKeypad extends StatelessWidget {
  const new({
    required this.onTap,
    required this.onBackspace,
    super.key,
    this.showDecimal = true,
  });

  final void Function(String) onTap;
  final VoidCallback onBackspace;
  final bool showDecimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Row(
            children: [
              for (var j = 1; j <= 3; j++)
                Expanded(
                  child: _KeypadButton(
                    text: '${i * 3 + j}',
                    onTap: () => onTap('${i * 3 + j}'),
                  ),
                ),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: showDecimal
                  ? _KeypadButton(
                      text: '.',
                      onTap: () => onTap('.'),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: _KeypadButton(
                text: '0',
                onTap: () => onTap('0'),
              ),
            ),
            Expanded(
              child: _KeypadButton(
                icon: Icons.backspace_outlined,
                onTap: onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const new({
    required this.onTap,
    this.text,
    this.icon,
  });

  final String? text;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 80,
            alignment: Alignment.center,
            child: text != null
                ? Text(
                    text!,
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : Icon(icon, size: 32),
          ),
        ),
      ),
    );
  }
}
