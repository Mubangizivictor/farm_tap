import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/alerts/farm_reminders.dart';
import 'package:farm_tap/core/people/domain/staff_permissions.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';

/// Who is using the phone now, for the farm's reminders (decision 0024).
ReminderViewer reminderViewer(SessionController session) {
  final farm = session.farm;
  final role = farm?.role;
  final staff = session.staff;
  final manages = staff == null
      ? role == PlaceRole.owner || role == PlaceRole.manager
      : StaffPermissions.managesStaff(staff.role);
  return ReminderViewer(
    farmName: farm?.name ?? '',
    staffId: staff?.id ?? farm?.staffId,
    manages: manages,
    // Only those who pay hear about the trial and the plan.
    trialEndsAt: manages ? farm?.subscription.trialEndsAt : null,
    paidUntil: manages ? farm?.subscription.paidUntil : null,
  );
}
