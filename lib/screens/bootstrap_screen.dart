import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/widgets/interrupted_restore_prompt.dart';
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

    // Before anything navigates: `context.go` below replaces the entire route
    // stack, which would take a dialog route with it. Awaiting the warning here
    // is what keeps it on screen long enough to be acted on — see
    // showInterruptedRestorePrompt.
    await showInterruptedRestorePromptFromFlag(
      context,
      flag: context.read<RestoreProgressFlag>(),
    );
    if (!mounted) {
      return;
    }

    final homeUiModel = context.read<HomeUiModel>();
    final feed = context.read<ComicFeedModel>();

    // Navigate first, load after. Awaiting the feed here left the user on a
    // spinner for the whole timeout-and-retry chain whenever the site was
    // unreachable — with no back button, no error and no retry, because the
    // screen that has all three is the one being waited for. The home tab
    // already shows its own loading state and, since P89, its own failure
    // and retry.
    homeUiModel.setLoading(true);
    context.go('/index');

    await feed.loadHomeFeed();
    if (!mounted) {
      return;
    }
    homeUiModel.setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(),
            Text(AppLocalizations.of(context)!.bootstrapLoading),
          ],
        ),
      ),
    );
  }
}
