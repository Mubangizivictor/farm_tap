import 'package:farm_tap/core/sync/data/isar/isar_record_store.dart';
import 'package:farm_tap/sectors/cattle/herd/data/models/animal_model.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([AnimalModelSchema, ...syncSchemas], directory: dir.path);
  }
}
