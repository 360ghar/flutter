import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/models/static_page_model.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/mixins/theme_mixin.dart';
import '../../../core/utils/app_colors.dart';

class PolicyPageView extends StatefulWidget with ThemeMixin {
  final String uniqueName;
  final String titleText;

  PolicyPageView({super.key, required this.uniqueName, required this.titleText});

  @override
  State<PolicyPageView> createState() => _PolicyPageViewState();
}

class _PolicyPageViewState extends State<PolicyPageView> {
  String? _markdownContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final StaticPageModel page = await ApiService.instance.fetchStaticPage(widget.uniqueName);

      setState(() {
        _markdownContent = page.content.trim().isNotEmpty ? page.content : 'No content available.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load content';
        _isLoading = false;
      });
    }
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primaryTextColor = theme.colorScheme.onSurface;
    final Color secondaryTextColor = AppColors.textSecondary;
    final Color linkColor = theme.colorScheme.primary;

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(color: primaryTextColor, height: 1.6),
      h1: theme.textTheme.headlineMedium?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w700,
      ),
      h2: theme.textTheme.headlineSmall?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w700,
      ),
      h3: theme.textTheme.titleLarge?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w700,
      ),
      h4: theme.textTheme.titleMedium?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w600,
      ),
      h5: theme.textTheme.titleSmall?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w600,
      ),
      h6: theme.textTheme.labelLarge?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w600,
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(left: BorderSide(color: AppColors.primaryYellow, width: 4)),
      ),
      blockSpacing: 16,
      listBulletPadding: const EdgeInsets.only(right: 8),
      listIndent: 24,
      textAlign: WrapAlignment.start,
      a: TextStyle(
        color: linkColor,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w500,
      ),
      code: TextStyle(
        backgroundColor: AppColors.inputBackground,
        color: primaryTextColor,
        fontFamily: 'monospace',
        fontSize: (theme.textTheme.bodySmall?.fontSize ?? 13) * 0.95,
      ),
      tableBorder: TableBorder.all(color: AppColors.divider, width: 1),
      tableHead: theme.textTheme.titleSmall?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w600,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
      tableCellsPadding: const EdgeInsets.all(12),
    );
  }

  Future<void> _handleLinkTap(String? href) async {
    if (href == null || href.isEmpty) {
      return;
    }

    final Uri? uri = Uri.tryParse(href);
    if (uri == null) {
      return;
    }

    try {
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('unable_to_open_link'.tr)));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('unable_to_open_link'.tr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_isLoading) {
      body = Center(child: CircularProgressIndicator(color: AppColors.loadingIndicator));
    } else if (_error != null) {
      body = Center(
        child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)),
      );
    } else if (_markdownContent == null || _markdownContent!.isEmpty) {
      body = Center(
        child: Text('no_content'.tr, style: TextStyle(color: AppColors.textSecondary)),
      );
    } else {
      body = Markdown(
        data: _markdownContent!,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        styleSheet: _buildMarkdownStyleSheet(context),
        selectable: true,
        onTapLink: (_, href, title) => _handleLinkTap(href),
      );
    }

    return (widget as ThemeMixin).buildThemeAwareScaffold(
      title: widget.titleText,
      body: SafeArea(child: body),
    );
  }
}
