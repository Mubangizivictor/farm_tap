import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/usecases/add_animal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHerdRepository extends Mock implements HerdRepository;

void main() {
  late AddAnimal usecase;
  late MockHerdRepository mockRepository;

  setUp(() {
    mockRepository = MockHerdRepository();
    usecase = AddAnimal(mockRepository);
  });

  final tAnimal = Animal(
    id: '1',
    tenantId: 't1',
    tagNumber: 'TAG1',
    name: 'Bessie',
    sex: AnimalSex.female,
    breed: 'Ankole',
    dateOfBirth: DateTime(2020),
    status: AnimalStatus.active,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    createdBy: 'u1',
    updatedBy: 'u1',
    deviceId: 'd1',
    syncStatus: SyncStatus.pending,
  );

  setUpAll(() => registerFallbackValue(tAnimal));

  test('should call addAnimal on the repository', () async {
    when(() => mockRepository.addAnimal(any())).thenAnswer((_) async => const Result.success(null));

    final result = await usecase(tAnimal);

    expect(result, isA<Success<void>>());
    verify(() => mockRepository.addAnimal(tAnimal));
    verifyNoMoreInteractions(mockRepository);
  });
}
