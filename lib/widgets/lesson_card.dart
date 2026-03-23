import 'package:gama/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showVisibility;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
    this.trailing,
    this.showVisibility = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Video icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: lesson.isFree
                        ? [
                            AppTheme.freeGreen,
                            AppTheme.freeGreen.withAlpha(180)
                          ]
                        : [
                            AppTheme.paidOrange,
                            AppTheme.paidOrange.withAlpha(180)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  lesson.isFree
                      ? Icons.play_circle_outline
                      : Icons.lock_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeBadge(context, l10n),
                      ],
                    ),
                    if (lesson.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (showVisibility) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            lesson.isVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 14,
                            color: lesson.isVisible
                                ? AppTheme.successGreen
                                : AppTheme.errorRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lesson.isVisible ? l10n.visible : l10n.hidden,
                            style: TextStyle(
                              fontSize: 12,
                              color: lesson.isVisible
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: lesson.isFree
            ? AppTheme.freeGreen.withAlpha(25)
            : AppTheme.paidOrange.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lesson.isFree
              ? AppTheme.freeGreen.withAlpha(100)
              : AppTheme.paidOrange.withAlpha(100),
        ),
      ),
      child: Text(
        lesson.isFree ? l10n.free : l10n.paid,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: lesson.isFree ? AppTheme.freeGreen : AppTheme.paidOrange,
        ),
      ),
    );
  }
}
