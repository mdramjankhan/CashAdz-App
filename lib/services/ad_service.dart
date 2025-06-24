import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdService {
  static Future<void> showInterstitialAd(BuildContext context, {Function? onAdClosed}) async {
    InterstitialAd.load(
      adUnitId: "ca-app-pub-3940256099942544/1033173712", // Replace with your real ad unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (onAdClosed != null) onAdClosed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (onAdClosed != null) onAdClosed();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (onAdClosed != null) onAdClosed();
        },
      ),
    );
  }

  static Future<void> showRewardedAd(BuildContext context, {required Function onRewarded}) async {
    RewardedAd.load(
      adUnitId: "ca-app-pub-3940256099942544/5224354917", // Replace with your real ad unit ID
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              onRewarded();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load ad. Please try again.')),
          );
        },
      ),
    );
  }
}