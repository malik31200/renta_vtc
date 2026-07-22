import 'package:flutter/material.dart';

import '../models/ride_result.dart';
import '../theme/app_theme.dart';
import '../utils/number_parsing.dart';

/// Bloc principal "taximètre" : net en gros caractères, détail
/// carburant/URSSAF/commission en dessous une fois le calcul effectué —
/// CLAUDE.md §6-7.1.
class ReadoutCard extends StatelessWidget {
  final RideResult? result;
  final double urssafRatePercent;
  final String fuelLabel;

  const ReadoutCard({
    super.key,
    required this.result,
    required this.urssafRatePercent,
    this.fuelLabel = 'Carburant',
  });

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    final netColor = result == null
        ? AppColors.textMuted
        : (result.net >= 0 ? AppColors.green : AppColors.red);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF14161B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NET ESTIMÉ POUR CETTE COURSE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result == null ? '—' : NumberParsing.formatAmount(result.net),
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: netColor,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Text('€', style: TextStyle(fontSize: 20, color: AppColors.textMuted)),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReadoutSubItem(
                    label: fuelLabel,
                    value: '−${NumberParsing.formatAmount(result.fuelCost)} €',
                  ),
                  const SizedBox(width: 18),
                  _ReadoutSubItem(
                    label: 'URSSAF ${NumberParsing.formatDecimal(urssafRatePercent)} %',
                    value: '−${NumberParsing.formatAmount(result.urssafCost)} €',
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _ReadoutSubItem(
                      label: 'Commission',
                      value:
                          '−${NumberParsing.formatAmount(result.commissionAmount)} € (${NumberParsing.formatDecimal(result.commissionRate * 100)} %)',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadoutSubItem extends StatelessWidget {
  final String label;
  final String value;

  const _ReadoutSubItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
