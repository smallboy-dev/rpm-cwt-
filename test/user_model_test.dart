import 'package:flutter_test/flutter_test.dart';
import '../lib/data/models/user_model.dart';

void main() {
  test('UserModel.toJson should not contain agency_id', () {
    final user = UserModel(
      id: '123',
      name: 'Test',
      email: 'test@example.com',
      role: UserRole.client,
      agencyId: 'some-agency',
    );

    final json = user.toJson();
    expect(json.containsKey('agency_id'), false);
    expect(json.containsKey('agency_role'), false);
    print('JSON Keys: ${json.keys}');
  });
}
