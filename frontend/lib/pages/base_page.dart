import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A base page. Other pages can build off this one while retaining some generic functionality/UI.
class BasePage extends StatelessWidget {
  /// The title displayed at the top.
  final String title;
  /// Whether to show a back button, which by default pops the router.
  final bool showBackButton;
  /// An optional callback in place of just popping the router.
  final VoidCallback? onBack;
  /// The body of the page.
  final Widget body;
  /// Optional actions for the page's app bar.
  final List<Widget>? appBarActions;
  /// Optional floating actions at the bottom of the page.
  final Widget? floatingActions;

  const BasePage({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.onBack,
    this.appBarActions,
    this.floatingActions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Navigator.pop(context),
              )
            : null,
        actions: appBarActions,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: body,
        ),
      ),
      floatingActionButton: floatingActions,
    );
  }
}
