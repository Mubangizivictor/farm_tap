import 'package:uuid/uuid.dart';

abstract class IdGenerator {
  String generate();
}

class UuidGenerator implements IdGenerator {
  final _uuid = const Uuid();

  @override
  String generate() => _uuid.v4();
}
