import 'package:flutter/material.dart';

import '../core/ui/doctor_shell_colors.dart';
import '../core/ui/doctor_ui_widgets.dart';
import 'doctor_shell_drawer.dart';

/// Doctor screens with optional drawer (dashboard) or back navigation (pushed routes).
class DoctorShellScaffold extends StatelessWidget {
  const DoctorShellScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.drawerRoute,
    this.floatingActionButton,
    this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final String? drawerRoute;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final useDrawer = drawerRoute != null;

    Widget content = body;
    if (onRefresh != null) {
      content = RefreshIndicator(
        color: DoctorShellColors.header,
        onRefresh: onRefresh!,
        child: body is ScrollView
            ? body
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: body,
              ),
      );
    }

    return Scaffold(
      backgroundColor: DoctorShellColors.canvas,
      drawer: useDrawer ? DoctorShellDrawer(currentRoute: drawerRoute) : null,
      appBar: DoctorUi.appBar(
        title: title,
        subtitle: subtitle,
        actions: actions,
        leading: useDrawer
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 28),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              )
            : canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: content),
    );
  }
}
