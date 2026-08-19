import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

class CrudSplitView extends StatelessWidget {
  final Widget header;
  final Widget master;
  final Widget detail;
  final int masterFlex;
  final int detailFlex;
  final bool isLoading;

  const CrudSplitView({
    super.key,
    required this.header,
    required this.master,
    required this.detail,
    this.masterFlex = 4,
    this.detailFlex = 6,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: masterFlex,
                child: master,
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: detailFlex,
                child: detail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
