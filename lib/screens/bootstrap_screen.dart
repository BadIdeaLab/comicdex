import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  bool _hasScheduledNavigation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeFeedAndNavigate();
    });
  }

  Future<void> _loadHomeFeedAndNavigate() async {
    if (_hasScheduledNavigation) {
      return;
    }
    _hasScheduledNavigation = true;

    final homeUiModel = context.read<HomeUiModel>();
    homeUiModel.setLoading(true);
    await context.read<ComicFeedModel>().loadHomeFeed();
    if (!mounted) {
      return;
    }
    homeUiModel.setLoading(false);
    context.go('/index');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            Text('Loading index...'),
          ],
        ),
      ),
    );
  }
}
