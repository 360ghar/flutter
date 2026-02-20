import 'package:flutter/material.dart';

import 'package:ghar360/core/design/app_design_extensions.dart';

class AuthPremiumShell extends StatelessWidget {
  const AuthPremiumShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.topTrailing,
    this.onBack,
    this.footer,
    this.chips = const <String>[],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? topTrailing;
  final VoidCallback? onBack;
  final Widget? footer;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppDesign.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppDesign.primaryYellow.withValues(alpha: 0.13),
                      AppDesign.background,
                      AppDesign.accentBlue.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: onBack != null
                  ? IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back))
                  : const SizedBox.shrink(),
            ),
            Positioned(top: 8, right: 8, child: topTrailing ?? const SizedBox.shrink()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppDesign.primaryYellow,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppDesign.primaryYellow.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_work_rounded,
                            color: AppDesign.textDark,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppDesign.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: AppDesign.textSecondary),
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: chips
                              .map(
                                (chip) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppDesign.surface,
                                    border: Border.all(color: AppDesign.border),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    chip,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: AppDesign.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 22),
                      AuthStageCard(child: child),
                      if (footer != null) ...[const SizedBox(height: 14), footer!],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthStageCard extends StatelessWidget {
  const AuthStageCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppDesign.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppDesign.border),
        boxShadow: AppDesign.getCardShadow(),
      ),
      child: Padding(padding: const EdgeInsets.fromLTRB(18, 20, 18, 18), child: child),
    );
  }
}

class AuthInlineError extends StatelessWidget {
  const AuthInlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppDesign.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesign.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppDesign.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppDesign.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
