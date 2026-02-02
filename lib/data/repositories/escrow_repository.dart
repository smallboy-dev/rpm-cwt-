import 'package:get/get.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../models/milestone_model.dart';
import '../services/wallet_service.dart';
import 'auth_repository.dart';
import 'project_repository.dart';
import 'agency_repository.dart';
import 'analytics_repository.dart';
import '../models/transaction_model.dart';

class EscrowRepository extends GetxService {
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final ProjectRepository _projectRepo = Get.find<ProjectRepository>();
  final WalletService _walletService = Get.find<WalletService>();

  Future<bool> fundEscrow(ProjectModel project) async {
    UserModel? currentUser = _authRepo.currentUser.value;
    if (currentUser == null ||
        currentUser.walletBalance < project.totalBudget) {
      return false;
    }

    // Deduct from client wallet
    UserModel updatedClient = currentUser.copyWith(
      walletBalance: currentUser.walletBalance - project.totalBudget,
    );
    _authRepo.setCurrentUser(updatedClient);

    // Add to project escrow
    project.escrowBalance = project.totalBudget;
    await _projectRepo.updateProject(project);
    return true;
  }

  Future<bool> fundOnChain(ProjectModel project) async {
    if (!_walletService.isConnected.value) return false;

    // Call WalletService to handle transaction
    await _walletService.fundProjectOnChain(
      project.id,
      project.developerId ?? '',
      project.totalBudget,
    );

    // Update project state
    project.escrowBalance = project.totalBudget;
    await _projectRepo.updateProject(project);
    return true;
  }

  Future<bool> fundFromAgency(ProjectModel project, String agencyId) async {
    final AgencyRepository agencyRepo = Get.find<AgencyRepository>();
    final agency = await agencyRepo.getAgency(agencyId);

    if (agency == null || agency.walletBalance < project.totalBudget) {
      return false;
    }

    // Deduct from agency wallet
    await agencyRepo.updateWalletBalance(agencyId, -project.totalBudget);

    // Add to project escrow
    project.escrowBalance = project.totalBudget;
    await _projectRepo.updateProject(project);
    return true;
  }

  Future<bool> releaseMilestone(
    ProjectModel project,
    String milestoneId,
  ) async {
    int index = project.milestones.indexWhere((m) => m.id == milestoneId);
    if (index == -1) return false;

    var milestone = project.milestones[index];
    if (milestone.status != MilestoneStatus.approved) return false;

    double amount = milestone.amount;
    if (project.escrowBalance < amount) return false; // Security check

    double platformFee = amount * 0.10;
    double developerNet = amount - platformFee;

    project.escrowBalance -= amount;
    project.milestones[index].status = MilestoneStatus.settled;

    // 1. Credit Developer Wallet (off-chain simulation)
    if (project.developerId != null) {
      final developer = await _authRepo.getUserById(project.developerId!);
      if (developer != null) {
        final updatedDev = developer.copyWith(
          walletBalance: developer.walletBalance + developerNet,
        );
        _authRepo.updateUser(updatedDev);
      }
    }

    // 2. Record Platform Fee
    final analyticsRepo = Get.find<AnalyticsRepository>();
    analyticsRepo.recordTransaction(
      FinancialTransactionModel(
        id: 'tx_fee_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'platform',
        amount: platformFee,
        type: TransactionType.platformFee,
        projectId: project.id,
        milestoneId: milestoneId,
        timestamp: DateTime.now(),
        description: 'Platform fee for milestone: ${milestone.title}',
      ),
    );

    // 3. Record Developer Payout
    analyticsRepo.recordTransaction(
      FinancialTransactionModel(
        id: 'tx_pay_${DateTime.now().millisecondsSinceEpoch}',
        userId: project.developerId ?? '',
        amount: developerNet,
        type: TransactionType.payment,
        projectId: project.id,
        milestoneId: milestoneId,
        timestamp: DateTime.now(),
        description: 'Payment for milestone: ${milestone.title}',
      ),
    );

    // Check if it was an on-chain escrow (simulation check)
    if (_walletService.isConnected.value) {
      await _walletService.releaseMilestoneOnChain(project.id, amount);
    }

    await _projectRepo.updateProject(project);
    return true;
  }
}
