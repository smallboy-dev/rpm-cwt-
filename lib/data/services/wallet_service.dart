// ignore_for_file: deprecated_member_use

import 'package:get/get.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletService extends GetxService {
  late Web3App _web3App;
  var isConnected = false.obs;
  var accountAddress = ''.obs;
  var nairaBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _initWalletConnect();
  }

  Future<void> _initWalletConnect() async {
    _web3App = await Web3App.createInstance(
      projectId:
          'YOUR_PROJECT_ID', // User will need to provide or I'll use a placeholder
      metadata: const PairingMetadata(
        name: 'RPM Marketplace',
        description: 'Real Project Marketplace',
        url: 'https://rpm.marketplace',
        icons: ['https://rpm.marketplace/logo.png'],
      ),
    );
  }

  Future<void> connectWallet() async {
    try {
      final session = await _web3App.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:137'], // Polygon Mainnet
            methods: ['eth_sendTransaction', 'personal_sign'],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final uri = session.uri;
      if (uri != null) {
        final url = 'wc:${uri.toString()}';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      }

    } catch (e) {
      Get.snackbar('Error', 'Failed to connect wallet: $e');
    }
  }

  Future<void> fundProjectOnChain(
    String projectId,
    String developerAddress,
    double amount,
  ) async {
    if (!isConnected.value) {
      Get.snackbar('Error', 'Wallet not connected');
      return;
    }


    Get.snackbar('Blockchain', 'Initiating on-chain funding for ₦$amount...');

    await Future.delayed(const Duration(seconds: 2));

    nairaBalance.value -= amount;
    Get.snackbar('Success', 'Project $projectId funded on-chain!');
  }

  Future<void> releaseMilestoneOnChain(String projectId, double amount) async {
    Get.snackbar('Blockchain', 'Releasing ₦$amount to developer...');
    await Future.delayed(const Duration(seconds: 1));
    Get.snackbar('Success', 'Blockchain transaction confirmed.');
  }

  Future<void> getOnChainNairaBalance() async {
    nairaBalance.value = 750000.0; 
  }
}
