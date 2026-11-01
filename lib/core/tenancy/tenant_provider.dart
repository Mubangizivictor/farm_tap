abstract class TenantProvider {
  String get currentTenantId;
}

class InMemoryTenantProvider implements TenantProvider {
  @override
  String get currentTenantId => 'default-tenant';
}
