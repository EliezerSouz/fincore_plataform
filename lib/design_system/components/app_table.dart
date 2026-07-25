import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';

class AppTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: const TableBorder(
          horizontalInside: BorderSide(color: AppColors.border),
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            children: columns
                .map((col) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        col,
                        style: AppTypography.text.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
          ),
          for (final row in rows)
            TableRow(
              children: row
                  .map((cell) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: cell,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
