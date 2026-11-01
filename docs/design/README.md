# FarmTap UI — V1 Dairy

102 screens × 4 form factors × light and dark = **816 screen images**, plus **19 cartoon animations** (light and dark, WebP and GIF).

## Folders

| Folder | Contents |
|---|---|
| `screens/phone/{light,dark}/` | Android phone app (390 × 844 dp, rendered at 2×) |
| `screens/tablet/{light,dark}/` | Tablet app, landscape (1194 × 834 dp, 1.5×) — navigation rail |
| `screens/web_desktop/{light,dark}/` | Web app on desktop (1440 × 900) — sidebar, tables, dialogs |
| `screens/web_mobile/{light,dark}/` | Web app in a phone browser (390 × 844, 2×) |
| `overview/` | One contact sheet per section (phone and desktop) — start here |
| `animation_posters/` | Still frame of every animation (for quick viewing) |
| `copy_into_farm_tap/` | Files to copy into your Flutter project (same paths) |
| `UX_SPEC.md` | Behaviour rules: breakpoints, popups, animations, states, accessibility |

## Install the animations in the app

From the folder where you unzipped:

```bash
cp -R farmtap_ui/copy_into_farm_tap/* ~/Desktop/Apps/farm_tap/
```

This adds `assets/animations/anim_*.webp|gif` (already covered by `assets/animations/` in pubspec.yaml) and replaces `lib/core/theme/farmtap_assets.dart` with a version that keeps all existing constants and adds `FarmTapAnimations`:

```dart
Image.asset(FarmTapAnimations.milkSaved.of(context), height: context.sizes.photoPreview)
```

## Screen file names

Same file name in every form factor and mode: `screens/<form_factor>/<light|dark>/<ID>_<name>.png`.

| ID | Screen file | Section | Notes (UX) |
|---|---|---|---|
| A01 | `A01_splash.png` | Launch & account | Native splash shows the logo; this animated splash plays for up to 2 s while the local database opens. Skip straight to Staff unlock if a farm is already signed in. |
| A02 | `A02_sign_in.png` | Launch & account | Google and email on Android; Apple shown on iOS. Language switch on this screen. No phone OTP. Buttons are 56 px tall. |
| A03 | `A03_email_sign_in.png` | Launch & account | Show/hide password eye. Keyboard 'Next' moves to password, 'Done' submits. Errors appear under the field, never as a popup. |
| A04 | `A04_email_sign_up.png` | Launch & account | Inline validation on blur. After sign-up a verification email is sent (A06) but the user can continue onboarding. |
| A05 | `A05_forgot_password.png` | Launch & account | Always show the same success message (do not reveal whether the email exists). |
| A06 | `A06_check_email.png` | Launch & account |  |
| A07 | `A07_farm_picker.png` | Launch & account |  |
| B01 | `B01_onboard_language.png` | Onboarding |  |
| B02 | `B02_onboard_sector.png` | Onboarding | Tapping a 'Coming soon' sector opens the waitlist sheet (B03). Only Dairy continues the setup. |
| B03 | `B03_onboard_waitlist_sheet.png` | Onboarding | Bottom sheet on phone, dialog on tablet/web. |
| B04 | `B04_onboard_waitlist_done.png` | Onboarding |  |
| B05 | `B05_onboard_dairy_type.png` | Onboarding |  |
| B06 | `B06_onboard_farm_details.png` | Onboarding |  |
| B07 | `B07_onboard_contacts.png` | Onboarding | Numbers are not verified by OTP. They show 'Not yet confirmed' until the first message is delivered. |
| B08 | `B08_onboard_role.png` | Onboarding |  |
| B09 | `B09_onboard_first_staff.png` | Onboarding |  |
| B10 | `B10_onboard_trial_started.png` | Onboarding | Plays the celebration animation once with a soft success sound and a short vibration. |
| C01 | `C01_staff_tap_card.png` | Staff unlock | NFC reader is listening while this screen is open (gold waves pulse). Haptic tick when a card is detected. |
| C02 | `C02_staff_card_number.png` | Staff unlock |  |
| C03 | `C03_staff_pin.png` | Staff unlock |  |
| C04 | `C04_staff_pin_wrong.png` | Staff unlock | Dots shake horizontally (300 ms) and the phone vibrates twice. After 5 wrong tries the card locks for 5 minutes. |
| C05 | `C05_nfc_unavailable.png` | Staff unlock | Confirmation dialog. |
| D01 | `D01_home_owner.png` | Home | Pull to refresh syncs. Metric cards open their section. 'Needs attention' is sorted by urgency (red first). |
| D02 | `D02_home_worker.png` | Home | What a worker sees after unlocking with a card. Only actions their role allows. Auto-locks after 5 min idle. |
| D03 | `D03_alerts.png` | Home |  |
| D04 | `D04_sync_status_sheet.png` | Home | Bottom sheet on phone, dialog on tablet/web. |
| D05 | `D05_home_offline.png` | Home |  |
| D06 | `D06_notification_permission.png` | Home | Shown once, after the first record is saved — never on first launch. Then the system permission prompt appears. |
| E01 | `E01_herd_list.png` | Herd | Phone: list with big avatars. Tablet/web: sortable table. Red 'Treated' badge means milk not for sale. |
| E02 | `E02_herd_filter_sheet.png` | Herd | Bottom sheet on phone, dialog on tablet/web. |
| E03 | `E03_animal_detail.png` | Herd |  |
| E04 | `E04_add_animal.png` | Herd |  |
| E05 | `E05_scan_qr.png` | Herd |  |
| E06 | `E06_record_event_sheet.png` | Herd | Bottom sheet on phone, dialog on tablet/web. |
| E07 | `E07_calf_born.png` | Herd | Full-screen celebration on phones, dialog on tablet/web. Calf record is created automatically and linked to the mother. |
| E08 | `E08_confirm_death.png` | Herd | Confirmation dialog. |
| E09 | `E09_head_count.png` | Herd |  |
| E10 | `E10_print_qr_labels.png` | Herd |  |
| F01 | `F01_milk_today.png` | Milk | Progress shows how many milking cows still need a record this session. |
| F02 | `F02_milk_pick_cow.png` | Milk | Big photo tiles. Green tick = already recorded; red = under treatment (milk not for sale). Tap a cow to open the keypad. |
| F03 | `F03_milk_keypad.png` | Milk | Each key press gives a light haptic tick and plays the number in Runyankore if voice prompts are on. Values above 30 L ask 'Are you sure?'. |
| F04 | `F04_milk_read_back.png` | Milk | Read-back is spoken aloud in Runyankore when voice is on. Nothing is saved until 'Yes'. |
| F05 | `F05_milk_saved.png` | Milk | Dancing milk cans play for ~1.5 s with a soft 'pop' sound. Auto-advances to the next unrecorded cow after 2 s unless the user taps. |
| F06 | `F06_treated_cow_warning.png` | Milk | Confirmation dialog. |
| F07 | `F07_milk_herd_total.png` | Milk |  |
| F08 | `F08_milk_use_split.png` | Milk |  |
| F09 | `F09_milk_sales.png` | Milk |  |
| F10 | `F10_milk_trends.png` | Milk |  |
| G01 | `G01_centre_home.png` | Collection centre |  |
| G02 | `G02_centre_tap_card.png` | Collection centre |  |
| G03 | `G03_centre_delivery_keypad.png` | Collection centre |  |
| G04 | `G04_centre_delivery_read_back.png` | Collection centre | Bottom sheet on phone, dialog on tablet/web. |
| G05 | `G05_centre_delivery_saved.png` | Collection centre | Delivery saves in under 15 s from tap. Toast offers Undo for 5 s. The screen returns to 'tap the next card' automatically. |
| G06 | `G06_centre_farmers.png` | Collection centre |  |
| G07 | `G07_centre_farmer_detail.png` | Collection centre |  |
| G08 | `G08_centre_close_session.png` | Collection centre | Confirmation dialog. |
| G09 | `G09_centre_statements.png` | Collection centre |  |
| G10 | `G10_centre_payment_sheet.png` | Collection centre |  |
| G11 | `G11_centre_sms_preview.png` | Collection centre |  |
| G12 | `G12_centre_quality_test.png` | Collection centre | Bottom sheet on phone, dialog on tablet/web. |
| G13 | `G13_centre_reconciliation.png` | Collection centre |  |
| H01 | `H01_health_home.png` | Health |  |
| H02 | `H02_add_treatment.png` | Health | Withdrawal date is calculated from the drug and shown before saving. Drug stock is reduced automatically. |
| H03 | `H03_treatment_saved.png` | Health | Full-screen celebration on phone, dialog on tablet/web. |
| H04 | `H04_drug_stock.png` | Health |  |
| H05 | `H05_health_schedule.png` | Health |  |
| H06 | `H06_withdrawal_list.png` | Health |  |
| I01 | `I01_feed_stock.png` | Feeding |  |
| I02 | `I02_record_feeding.png` | Feeding |  |
| I03 | `I03_feed_purchase_sheet.png` | Feeding | Bottom sheet on phone, dialog on tablet/web. |
| J01 | `J01_breeding_calendar.png` | Breeding |  |
| J02 | `J02_record_service_sheet.png` | Breeding | Bottom sheet on phone, dialog on tablet/web. |
| J03 | `J03_pregnancy_confirmed.png` | Breeding | Full-screen celebration on phone, dialog on tablet/web. |
| K01 | `K01_staff_list.png` | Workers |  |
| K02 | `K02_staff_detail.png` | Workers |  |
| K03 | `K03_assign_card.png` | Workers |  |
| K04 | `K04_attendance.png` | Workers |  |
| K05 | `K05_tasks.png` | Workers |  |
| K06 | `K06_wages.png` | Workers |  |
| L01 | `L01_money_overview.png` | Money |  |
| L02 | `L02_add_expense.png` | Money |  |
| L03 | `L03_reports.png` | Money |  |
| L04 | `L04_whatsapp_report_preview.png` | Money |  |
| M01 | `M01_subscription.png` | Subscription |  |
| M02 | `M02_pay_mobile_money.png` | Subscription | Phase A (manual): an admin confirms the ID. Phase B: one tap sends a payment prompt to the phone and activates automatically. |
| M03 | `M03_payment_confirmed.png` | Subscription | Full-screen celebration on phone, dialog on tablet/web. |
| M04 | `M04_trial_ending_popup.png` | Subscription | Shown on day 13 and day 14 once per day, never during recording. |
| M05 | `M05_read_only_locked.png` | Subscription | All record buttons are disabled with a lock icon. Data kept 90 days. Reports and export still work. |
| N01 | `N01_more_menu.png` | Settings |  |
| N02 | `N02_settings.png` | Settings |  |
| N03 | `N03_farm_profile.png` | Settings |  |
| N04 | `N04_language_sheet.png` | Settings | Bottom sheet on phone, dialog on tablet/web. |
| N05 | `N05_help_support.png` | Settings |  |
| N06 | `N06_sign_out_confirm.png` | Settings | Confirmation dialog. |
| N07 | `N07_delete_account.png` | Settings |  |
| O01 | `O01_admin_payments.png` | Admin (Victorbee) | Confirming activates the subscription and sends a WhatsApp receipt. Every action is audit-logged. |
| P01 | `P01_empty_herd.png` | System states |  |
| P02 | `P02_error_state.png` | System states |  |
| P03 | `P03_camera_permission.png` | System states | Confirmation dialog. |
| P04 | `P04_manager_pin_required.png` | System states | Confirmation dialog. |
| P05 | `P05_offline_saved_toast.png` | System states | Snackbar / toast, auto-hides after 3 s. |
| P06 | `P06_sync_done_toast.png` | System states | Snackbar / toast, auto-hides after 3 s. |
