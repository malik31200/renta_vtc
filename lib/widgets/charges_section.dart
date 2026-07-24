import 'package:flutter/material.dart';

import '../models/fixed_expense.dart';
import '../models/fuel_entry.dart';
import '../models/ride_entry.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatting.dart';
import '../utils/number_parsing.dart';

/// Charges du mois (Premium) : net réel après charges fixes (assurance, RC
/// pro...) et carburant réellement dépensé, à la place du carburant
/// théorique basé uniquement sur la distance course — retour d'un chauffeur
/// testeur, voir StatsService.realNetForMonth pour la logique de calcul.
class ChargesSection extends StatelessWidget {
  final List<RideEntry> entries;
  final List<FixedExpense> fixedExpenses;
  final List<FuelEntry> fuelEntries;
  final bool isElectric;
  final ValueChanged<FixedExpense> onAddFixedExpense;
  final ValueChanged<FixedExpense> onDeleteFixedExpense;
  final ValueChanged<FuelEntry> onAddFuelEntry;
  final ValueChanged<FuelEntry> onDeleteFuelEntry;

  const ChargesSection({
    super.key,
    required this.entries,
    required this.fixedExpenses,
    required this.fuelEntries,
    required this.isElectric,
    required this.onAddFixedExpense,
    required this.onDeleteFixedExpense,
    required this.onAddFuelEntry,
    required this.onDeleteFuelEntry,
  });

  @override
  Widget build(BuildContext context) {
    const stats = StatsService();
    final now = DateTime.now();
    final realNet = stats.realNetForMonth(entries, fixedExpenses, fuelEntries, now);
    final fuelLabel = isElectric ? 'Électricité' : 'Carburant';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RealNetCard(realNet: realNet, fuelLabel: fuelLabel),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Charges fixes',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        _ChargesCard(
          child: Column(
            children: [
              for (final expense in fixedExpenses)
                _ChargeRow(
                  label: expense.label,
                  amountText: '${NumberParsing.formatAmount(expense.amountPerMonth)} € / mois',
                  onDelete: () => onDeleteFixedExpense(expense),
                ),
              if (fixedExpenses.isNotEmpty) const Divider(height: 1, color: AppColors.divider),
              _AddButton(
                label: 'Ajouter une charge fixe',
                onTap: () => _showAddFixedExpenseDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            fuelLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        _ChargesCard(
          child: Column(
            children: [
              for (final entry in [...fuelEntries]..sort((a, b) => b.date.compareTo(a.date)))
                _ChargeRow(
                  label: DateFormatting.formatDateOnly(entry.date),
                  amountText: '${NumberParsing.formatAmount(entry.amount)} €',
                  onDelete: () => onDeleteFuelEntry(entry),
                ),
              if (fuelEntries.isNotEmpty) const Divider(height: 1, color: AppColors.divider),
              _AddButton(
                label: 'Ajouter un plein',
                onTap: () => _showAddFuelEntryDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddFixedExpenseDialog(BuildContext context) async {
    final labelController = TextEditingController();
    final amountController = TextEditingController();

    final result = await showDialog<FixedExpense>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Charge fixe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Intitulé (ex: Assurance)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Montant / mois (€)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final label = labelController.text.trim();
              final amount = NumberParsing.parse(amountController.text);
              if (label.isEmpty || amount <= 0) return;
              Navigator.pop(
                context,
                FixedExpense(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  label: label,
                  amountPerMonth: amount,
                ),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null) onAddFixedExpense(result);
  }

  Future<void> _showAddFuelEntryDialog(BuildContext context) async {
    final amountController = TextEditingController();

    final result = await showDialog<FuelEntry>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isElectric ? 'Nouvelle recharge' : 'Nouveau plein'),
        content: TextField(
          controller: amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Montant (€)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final amount = NumberParsing.parse(amountController.text);
              if (amount <= 0) return;
              Navigator.pop(
                context,
                FuelEntry(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  amount: amount,
                ),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null) onAddFuelEntry(result);
  }
}

class _RealNetCard extends StatelessWidget {
  final RealMonthlyNet realNet;
  final String fuelLabel;

  const _RealNetCard({required this.realNet, required this.fuelLabel});

  @override
  Widget build(BuildContext context) {
    final color = realNet.realNet >= 0 ? AppColors.green : AppColors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Net réel du mois',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberParsing.formatAmount(realNet.realNet)} €',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          _BreakdownLine('Net théorique (courses)', realNet.theoreticalNet),
          if (realNet.hasFuelEntries) ...[
            _BreakdownLine('+ $fuelLabel déjà déduit sur les courses', realNet.fuelTheoretical),
            _BreakdownLine('− $fuelLabel réel du mois', -realNet.realFuel),
          ],
          if (realNet.fixedCharges > 0) _BreakdownLine('− Charges fixes', -realNet.fixedCharges),
          if (!realNet.hasFuelEntries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Ajoute au moins une entrée de $fuelLabel ce mois-ci pour remplacer le montant théorique par ta dépense réelle.',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  final String label;
  final double value;

  const _BreakdownLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
          Text(
            '${NumberParsing.formatAmount(value)} €',
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargesCard extends StatelessWidget {
  final Widget child;

  const _ChargesCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _ChargeRow extends StatelessWidget {
  final String label;
  final String amountText;
  final VoidCallback onDelete;

  const _ChargeRow({required this.label, required this.amountText, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text(
            amountText,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.amber,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
            onPressed: onDelete,
            tooltip: 'Supprimer',
            padding: const EdgeInsets.only(left: 6),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.amber),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.amber)),
          ],
        ),
      ),
    );
  }
}
