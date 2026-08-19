import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

class CrudWorkspace extends StatelessWidget {
  final Widget header;
  final Widget master;
  final Widget? inspector;
  final Widget? editorSheet;
  final bool isInspectorOpen;
  final bool isEditing;
  final bool isLoading;

  const CrudWorkspace({
    super.key,
    required this.header,
    required this.master,
    this.inspector,
    this.editorSheet,
    this.isInspectorOpen = false,
    this.isEditing = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: FincoreColors.primary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 16),
        Expanded(
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isInspectorOpen ? 58 : 100,
                    child: master,
                  ),
                  if (isInspectorOpen && inspector != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? FincoreColors.surface : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? FincoreColors.border : Theme.of(context).dividerColor),
                        ),
                        child: inspector!,
                      ),
                    ),
                  ],
                ],
              ),
              if (isEditing && editorSheet != null)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 520,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? FincoreColors.surface : Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? FincoreColors.border : Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: editorSheet!,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
