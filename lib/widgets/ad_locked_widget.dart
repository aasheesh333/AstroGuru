import 'package:flutter/material.dart';
import 'package:astroguru/theme/app_colors.dart';
import 'package:astroguru/services/ad_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AdLockedWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onUnlock;
  final Widget? child; // Optional: show blurred content behind

  const AdLockedWidget({
    super.key,
    required this.title,
    required this.message,
    required this.onUnlock,
    this.child,
  });

  @override
  State<AdLockedWidget> createState() => _AdLockedWidgetState();
}

class _AdLockedWidgetState extends State<AdLockedWidget> {
  bool _isLoading = false;

  void _showAd() {
    setState(() {
      _isLoading = true;
    });

    AdService().showRewardedAd(
      onUserEarnedReward: (reward) {
        if (!mounted) return;
        // Unlock happens here
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        widget.onUnlock();
      },
      onAdDismissed: () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      },
      onAdFailed: () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adLoadFailed)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        if (widget.child != null)
           Opacity(opacity: 0.1, child: IgnorePointer(child: widget.child)),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.primaryGold,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.primaryGold)
                    : ElevatedButton.icon(
                        onPressed: _showAd,
                        icon: const Icon(Icons.play_circle_filled, color: Colors.black),
                        label: Text(
                          l10n.watchAdToUnlock,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
