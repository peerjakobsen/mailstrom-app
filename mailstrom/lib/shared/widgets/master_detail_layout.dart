import 'package:flutter/material.dart';

class MasterDetailLayout extends StatefulWidget {
  final Widget master;
  final Widget detail;
  final double initialMasterWidth;
  final double minMasterWidth;
  final double maxMasterWidth;

  const MasterDetailLayout({
    super.key,
    required this.master,
    required this.detail,
    this.initialMasterWidth = 320,
    this.minMasterWidth = 200,
    this.maxMasterWidth = 600,
  });

  @override
  State<MasterDetailLayout> createState() => _MasterDetailLayoutState();
}

class _MasterDetailLayoutState extends State<MasterDetailLayout> {
  late double _masterWidth;

  @override
  void initState() {
    super.initState();
    _masterWidth = widget.initialMasterWidth;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: _masterWidth,
          child: widget.master,
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _masterWidth = (_masterWidth + details.delta.dx).clamp(
                  widget.minMasterWidth,
                  widget.maxMasterWidth,
                );
              });
            },
            child: SizedBox(
              width: 8,
              child: Center(
                child: VerticalDivider(
                  width: 1,
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: widget.detail),
      ],
    );
  }
}
