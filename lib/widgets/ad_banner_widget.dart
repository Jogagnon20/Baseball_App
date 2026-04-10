import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Bannière publicitaire discrète (320×50).
/// Cycle automatique : visible 30 secondes, cachée 90 secondes.
/// S'anime en glissant vers le bas pour disparaître.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget>
    with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isVisible = true;

  Timer? _hideTimer;
  Timer? _showTimer;

  // Durée pendant laquelle la bannière reste visible
  static const _visibleDuration = Duration(seconds: 30);
  // Durée pendant laquelle la bannière est cachée
  static const _hiddenDuration = Duration(seconds: 90);

  // TODO: Remplacer par votre vrai Ad Unit ID AdMob avant publication
  static const String _adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 0, // 0 = visible (en position normale)
    );

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1), // glisse vers le bas et sort
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));

    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
            _startCycle();
          }
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    ad.load();
    _bannerAd = ad;
  }

  /// Démarre le cycle visible → caché → visible → …
  void _startCycle() {
    _hideTimer?.cancel();
    _showTimer?.cancel();

    // Après _visibleDuration, cacher la bannière
    _hideTimer = Timer(_visibleDuration, () {
      if (!mounted) return;
      _animCtrl.forward(); // glisse vers le bas
      setState(() => _isVisible = false);

      // Après _hiddenDuration, réafficher la bannière
      _showTimer = Timer(_hiddenDuration, () {
        if (!mounted) return;
        _animCtrl.reverse(); // remonte
        setState(() => _isVisible = true);
        _startCycle(); // relance le cycle
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _animCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) return const SizedBox.shrink();

    return ClipRect(
      child: SlideTransition(
        position: _slideAnim,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
