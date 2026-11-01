import 'dart:developer' as developer;

abstract class AuditLogger {
  Future<void> log(String action, {Map<String, dynamic>? metadata});
}

class LocalAuditLogger implements AuditLogger {
  @override
  Future<void> log(String action, {Map<String, dynamic>? metadata}) async {
    // In a real app, this would write to a local Isar collection
    // For now, we just log it.
    developer.log('AUDIT: $action | Metadata: $metadata');
  }
}
