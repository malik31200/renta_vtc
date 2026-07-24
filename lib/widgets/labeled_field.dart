import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Une ligne de champ de saisie : icône + label (+ sous-texte optionnel) +
/// input aligné à droite avec suffixe — CLAUDE.md §6. Toute la ligne est
/// tactile : taper sur l'icône ou le label active aussi le clavier, pas
/// seulement l'input lui-même (retour testeur, sinon la zone cliquable
/// perçue comme "le champ" est trop étroite).
class LabeledField extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final TextEditingController controller;
  final String? suffix;
  final Color valueColor;
  final double inputWidth;
  final TextAlign textAlign;
  final bool numeric;

  /// Si true, l'input prend l'espace restant de la ligne au lieu d'une
  /// largeur fixe — pour les champs texte libre (ex: nom du véhicule) dont
  /// le contenu ne doit pas être tronqué visuellement pendant la saisie.
  final bool expandInput;

  const LabeledField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.sublabel,
    this.suffix,
    this.valueColor = AppColors.amber,
    this.inputWidth = 70,
    this.textAlign = TextAlign.right,
    this.numeric = true,
    this.expandInput = false,
  });

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        if (widget.sublabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.sublabel!,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
      ],
    );

    final textField = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      textAlign: widget.textAlign,
      keyboardType: widget.numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: widget.numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
          : null,
      style: TextStyle(
        fontFamily: AppTheme.monoFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: widget.valueColor,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(widget.icon, size: 16, color: AppColors.textMuted),
            ),
            const SizedBox(width: 10),
            widget.expandInput ? labelColumn : Expanded(child: labelColumn),
            if (widget.expandInput) const SizedBox(width: 16),
            widget.expandInput
                ? Expanded(child: textField)
                : SizedBox(width: widget.inputWidth, child: textField),
            if (widget.suffix != null) ...[
              const SizedBox(width: 4),
              Text(widget.suffix!, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}
