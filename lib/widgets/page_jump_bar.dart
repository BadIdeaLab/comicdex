import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PageJumpBar extends StatefulWidget {
  const PageJumpBar({
    super.key,
    required this.currentPage,
    required this.onJump,
    this.totalPages,
  });

  final int currentPage;
  final int? totalPages;
  final Future<void> Function(int page) onJump;

  @override
  State<PageJumpBar> createState() => _PageJumpBarState();
}

class _PageJumpBarState extends State<PageJumpBar> {
  late final TextEditingController _controller;
  bool _isJumping = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentPage}');
  }

  @override
  void didUpdateWidget(PageJumpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _controller.text = '${widget.currentPage}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _jump(int page) async {
    final target = widget.totalPages != null
        ? page.clamp(1, widget.totalPages!)
        : page.clamp(1, 1 << 31);
    if (target == widget.currentPage) return;
    setState(() => _isJumping = true);
    try {
      await widget.onJump(target);
    } finally {
      if (mounted) setState(() => _isJumping = false);
    }
  }

  Future<void> _submitInput() async {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 1) {
      _controller.text = '${widget.currentPage}';
      return;
    }
    await _jump(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.totalPages;
    final atFirst = widget.currentPage <= 1;
    final atLast = total != null && widget.currentPage >= total;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: (_isJumping || atFirst) ? null : () => _jump(widget.currentPage - 1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous page',
        ),
        SizedBox(
          width: 48,
          child: TextField(
            controller: _controller,
            enabled: !_isJumping,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              border: OutlineInputBorder(),
            ),
            style: theme.textTheme.bodySmall,
            onSubmitted: (_) => _submitInput(),
          ),
        ),
        if (total != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '/ $total',
              style: theme.textTheme.bodySmall,
            ),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: (_isJumping || atLast) ? null : () => _jump(widget.currentPage + 1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next page',
        ),
        if (_isJumping)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}
