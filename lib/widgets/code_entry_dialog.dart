import 'package:flutter/material.dart';
import 'package:gama_app/l10n/app_localizations.dart';
import '../config/theme.dart';

class CodeEntryDialog extends StatefulWidget {
  final String lessonTitle;
  final Function(String code) onSubmit;

  const CodeEntryDialog({
    super.key,
    required this.lessonTitle,
    required this.onSubmit,
  });

  @override
  State<CodeEntryDialog> createState() => _CodeEntryDialogState();
}

class _CodeEntryDialogState extends State<CodeEntryDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.paidOrange.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 40,
                color: AppTheme.paidOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.paidLesson,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.lessonTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.enterCode,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                labelText: l10n.code,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  letterSpacing: 4,
                ),
                counterText: '',
              ),
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _submit(l10n),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _submit(l10n),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.confirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(AppLocalizations l10n) {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isNotEmpty) {
      setState(() => _isLoading = true);
      widget.onSubmit(code);
    }
  }
}
