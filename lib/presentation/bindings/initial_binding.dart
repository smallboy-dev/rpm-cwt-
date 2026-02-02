import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/escrow_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/bid_repository.dart';
import '../../data/repositories/dispute_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/kyc_repository.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/agency_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_project_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../data/repositories/supabase_bid_repository.dart';
import '../../data/repositories/supabase_collaboration_repository.dart';
import '../../data/repositories/supabase_kyc_repository.dart';
import '../../data/services/wallet_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/security_service.dart';
import '../../data/services/matching_service.dart';
import '../../data/services/collaboration_service.dart';
import '../../data/repositories/payout_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/agency_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services & Basic Repos
    Get.put(AnalyticsRepository());
    Get.put(PayoutRepository());
    Get.put(SecurityService());
    Get.put(MatchingService());
    Get.put(CollaborationService());
    Get.put(WalletService());
    Get.put(PaymentService());
    Get.put(AgencyRepository());
    Get.put<AuthRepository>(SupabaseAuthRepository());
    Get.put<ProjectRepository>(SupabaseProjectRepository());
    Get.put(EscrowRepository());
    Get.put<ChatRepository>(SupabaseChatRepository());
    Get.put<CollaborationRepository>(SupabaseCollaborationRepository());
    Get.put<BidRepository>(SupabaseBidRepository());
    Get.put(DisputeRepository());
    Get.put(ReviewRepository());
    Get.put<NotificationRepository>(SupabaseNotificationRepository());
    Get.put<KYCRepository>(SupabaseKYCRepository());
    Get.put<ProfileRepository>(SupabaseProfileRepository());

    // Core Managers
    Get.put(AuthController());
    Get.put(NotificationController());
    Get.put(AdminController());
    Get.put(AgencyController());
  }
}
