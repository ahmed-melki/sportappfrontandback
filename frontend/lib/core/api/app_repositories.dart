import 'api_client.dart';
import 'auth_repository.dart';
import 'repositories.dart';
import 'mock_repositories.dart';
import 'token_storage.dart';
import 'config.dart';

class AppRepositories {
  AppRepositories({
    void Function()? onUnauthorized,
    void Function(String email)? onEmailNotVerified,
    bool? mock,
  }) : client = ApiClient(onUnauthorized: onUnauthorized, onEmailNotVerified: onEmailNotVerified),
       storage = TokenStorage() {
    if (mock ?? useMockData) {
      final mockProfile = MockProfileRepository();
      auth = MockAuthRepository();
      profile = mockProfile;
      training = MockTrainingRepository();
      shop = MockShopRepository();
    } else {
      auth = ApiAuthRepository(client, storage);
      profile = ApiProfileRepository(client);
      training = ApiTrainingRepository(client);
      shop = ApiShopRepository(client);
    }
  }

  final ApiClient client;
  final TokenStorage storage;
  late final AuthRepository auth;
  late final ProfileRepository profile;
  late final TrainingRepository training;
  late final ShopRepository shop;
}

AppRepositories createRepositories({
  void Function()? onUnauthorized,
  void Function(String email)? onEmailNotVerified,
  bool? mock,
}) => AppRepositories(
  onUnauthorized: onUnauthorized,
  onEmailNotVerified: onEmailNotVerified,
  mock: mock,
);
