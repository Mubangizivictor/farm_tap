# FarmTap UI rebuild — progress

Tracks every screen against its mockups (see `docs/UI_REBUILD_PROMPT.md`).
Cell legend: `—` not started · `wip` built, not matched · score (from `tool/compare_mockups.py`) once the compare image has been reviewed.
Columns: P = phone, T = tablet, D = web_desktop, M = web_mobile; L = light, K = dark.

| ID | Screen | Section | P·L | P·K | T·L | T·K | D·L | D·K | M·L | M·K | Score | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A01 | A01_splash | Launch & account | — | — | — | — | — | — | — | — | | |
| A02 | A02_sign_in | Launch & account | wip | wip | wip | wip | wip | wip | wip | wip | 79–90 | old stub, rewrite |
| A03 | A03_email_sign_in | Launch & account | — | — | — | — | — | — | — | — | | |
| A04 | A04_email_sign_up | Launch & account | — | — | — | — | — | — | — | — | | |
| A05 | A05_forgot_password | Launch & account | — | — | — | — | — | — | — | — | | |
| A06 | A06_check_email | Launch & account | — | — | — | — | — | — | — | — | | |
| A07 | A07_farm_picker | Launch & account | — | — | — | — | — | — | — | — | | |
| B01 | B01_onboard_language | Onboarding | — | — | — | — | — | — | — | — | | |
| B02 | B02_onboard_sector | Onboarding | — | — | — | — | — | — | — | — | | |
| B03 | B03_onboard_waitlist_sheet | Onboarding | — | — | — | — | — | — | — | — | | |
| B04 | B04_onboard_waitlist_done | Onboarding | — | — | — | — | — | — | — | — | | |
| B05 | B05_onboard_dairy_type | Onboarding | — | — | — | — | — | — | — | — | | |
| B06 | B06_onboard_farm_details | Onboarding | — | — | — | — | — | — | — | — | | |
| B07 | B07_onboard_contacts | Onboarding | — | — | — | — | — | — | — | — | | |
| B08 | B08_onboard_role | Onboarding | — | — | — | — | — | — | — | — | | |
| B09 | B09_onboard_first_staff | Onboarding | — | — | — | — | — | — | — | — | | |
| B10 | B10_onboard_trial_started | Onboarding | — | — | — | — | — | — | — | — | | |
| C01 | C01_staff_tap_card | Staff unlock | — | — | — | — | — | — | — | — | | |
| C02 | C02_staff_card_number | Staff unlock | — | — | — | — | — | — | — | — | | |
| C03 | C03_staff_pin | Staff unlock | — | — | — | — | — | — | — | — | | |
| C04 | C04_staff_pin_wrong | Staff unlock | — | — | — | — | — | — | — | — | | |
| C05 | C05_nfc_unavailable | Staff unlock | — | — | — | — | — | — | — | — | | |
| D01 | D01_home_owner | Home | — | — | — | — | — | — | — | — | | |
| D02 | D02_home_worker | Home | — | — | — | — | — | — | — | — | | |
| D03 | D03_alerts | Home | — | — | — | — | — | — | — | — | | |
| D04 | D04_sync_status_sheet | Home | — | — | — | — | — | — | — | — | | |
| D05 | D05_home_offline | Home | — | — | — | — | — | — | — | — | | |
| D06 | D06_notification_permission | Home | — | — | — | — | — | — | — | — | | |
| E01 | E01_herd_list | Herd | — | — | — | — | — | — | — | — | | |
| E02 | E02_herd_filter_sheet | Herd | — | — | — | — | — | — | — | — | | |
| E03 | E03_animal_detail | Herd | — | — | — | — | — | — | — | — | | |
| E04 | E04_add_animal | Herd | — | — | — | — | — | — | — | — | | |
| E05 | E05_scan_qr | Herd | — | — | — | — | — | — | — | — | | |
| E06 | E06_record_event_sheet | Herd | — | — | — | — | — | — | — | — | | |
| E07 | E07_calf_born | Herd | — | — | — | — | — | — | — | — | | |
| E08 | E08_confirm_death | Herd | — | — | — | — | — | — | — | — | | |
| E09 | E09_head_count | Herd | — | — | — | — | — | — | — | — | | |
| E10 | E10_print_qr_labels | Herd | — | — | — | — | — | — | — | — | | |
| F01 | F01_milk_today | Milk | — | — | — | — | — | — | — | — | | |
| F02 | F02_milk_pick_cow | Milk | — | — | — | — | — | — | — | — | | |
| F03 | F03_milk_keypad | Milk | — | — | — | — | — | — | — | — | | |
| F04 | F04_milk_read_back | Milk | — | — | — | — | — | — | — | — | | |
| F05 | F05_milk_saved | Milk | — | — | — | — | — | — | — | — | | |
| F06 | F06_treated_cow_warning | Milk | — | — | — | — | — | — | — | — | | |
| F07 | F07_milk_herd_total | Milk | — | — | — | — | — | — | — | — | | |
| F08 | F08_milk_use_split | Milk | — | — | — | — | — | — | — | — | | |
| F09 | F09_milk_sales | Milk | — | — | — | — | — | — | — | — | | |
| F10 | F10_milk_trends | Milk | — | — | — | — | — | — | — | — | | |
| G01 | G01_centre_home | Collection centre | — | — | — | — | — | — | — | — | | |
| G02 | G02_centre_tap_card | Collection centre | — | — | — | — | — | — | — | — | | |
| G03 | G03_centre_delivery_keypad | Collection centre | — | — | — | — | — | — | — | — | | |
| G04 | G04_centre_delivery_read_back | Collection centre | — | — | — | — | — | — | — | — | | |
| G05 | G05_centre_delivery_saved | Collection centre | — | — | — | — | — | — | — | — | | |
| G06 | G06_centre_farmers | Collection centre | — | — | — | — | — | — | — | — | | |
| G07 | G07_centre_farmer_detail | Collection centre | — | — | — | — | — | — | — | — | | |
| G08 | G08_centre_close_session | Collection centre | — | — | — | — | — | — | — | — | | |
| G09 | G09_centre_statements | Collection centre | — | — | — | — | — | — | — | — | | |
| G10 | G10_centre_payment_sheet | Collection centre | — | — | — | — | — | — | — | — | | |
| G11 | G11_centre_sms_preview | Collection centre | — | — | — | — | — | — | — | — | | |
| G12 | G12_centre_quality_test | Collection centre | — | — | — | — | — | — | — | — | | |
| G13 | G13_centre_reconciliation | Collection centre | — | — | — | — | — | — | — | — | | |
| H01 | H01_health_home | Health | — | — | — | — | — | — | — | — | | |
| H02 | H02_add_treatment | Health | — | — | — | — | — | — | — | — | | |
| H03 | H03_treatment_saved | Health | — | — | — | — | — | — | — | — | | |
| H04 | H04_drug_stock | Health | — | — | — | — | — | — | — | — | | |
| H05 | H05_health_schedule | Health | — | — | — | — | — | — | — | — | | |
| H06 | H06_withdrawal_list | Health | — | — | — | — | — | — | — | — | | |
| I01 | I01_feed_stock | Feeding | — | — | — | — | — | — | — | — | | |
| I02 | I02_record_feeding | Feeding | — | — | — | — | — | — | — | — | | |
| I03 | I03_feed_purchase_sheet | Feeding | — | — | — | — | — | — | — | — | | |
| J01 | J01_breeding_calendar | Breeding | — | — | — | — | — | — | — | — | | |
| J02 | J02_record_service_sheet | Breeding | — | — | — | — | — | — | — | — | | |
| J03 | J03_pregnancy_confirmed | Breeding | — | — | — | — | — | — | — | — | | |
| K01 | K01_staff_list | Workers | — | — | — | — | — | — | — | — | | |
| K02 | K02_staff_detail | Workers | — | — | — | — | — | — | — | — | | |
| K03 | K03_assign_card | Workers | — | — | — | — | — | — | — | — | | |
| K04 | K04_attendance | Workers | — | — | — | — | — | — | — | — | | |
| K05 | K05_tasks | Workers | — | — | — | — | — | — | — | — | | |
| K06 | K06_wages | Workers | — | — | — | — | — | — | — | — | | |
| L01 | L01_money_overview | Money | — | — | — | — | — | — | — | — | | |
| L02 | L02_add_expense | Money | — | — | — | — | — | — | — | — | | |
| L03 | L03_reports | Money | — | — | — | — | — | — | — | — | | |
| L04 | L04_whatsapp_report_preview | Money | — | — | — | — | — | — | — | — | | |
| M01 | M01_subscription | Subscription | — | — | — | — | — | — | — | — | | |
| M02 | M02_pay_mobile_money | Subscription | — | — | — | — | — | — | — | — | | |
| M03 | M03_payment_confirmed | Subscription | — | — | — | — | — | — | — | — | | |
| M04 | M04_trial_ending_popup | Subscription | — | — | — | — | — | — | — | — | | |
| M05 | M05_read_only_locked | Subscription | — | — | — | — | — | — | — | — | | |
| N01 | N01_more_menu | Settings | — | — | — | — | — | — | — | — | | |
| N02 | N02_settings | Settings | — | — | — | — | — | — | — | — | | |
| N03 | N03_farm_profile | Settings | — | — | — | — | — | — | — | — | | |
| N04 | N04_language_sheet | Settings | — | — | — | — | — | — | — | — | | |
| N05 | N05_help_support | Settings | — | — | — | — | — | — | — | — | | |
| N06 | N06_sign_out_confirm | Settings | — | — | — | — | — | — | — | — | | |
| N07 | N07_delete_account | Settings | — | — | — | — | — | — | — | — | | |
| O01 | O01_admin_payments | Admin (Victorbee) | — | — | — | — | — | — | — | — | | |
| P01 | P01_empty_herd | System states | — | — | — | — | — | — | — | — | | |
| P02 | P02_error_state | System states | — | — | — | — | — | — | — | — | | |
| P03 | P03_camera_permission | System states | — | — | — | — | — | — | — | — | | |
| P04 | P04_manager_pin_required | System states | — | — | — | — | — | — | — | — | | |
| P05 | P05_offline_saved_toast | System states | — | — | — | — | — | — | — | — | | |
| P06 | P06_sync_done_toast | System states | — | — | — | — | — | — | — | — | | |

## UI kit audit (Step 1)

Audited `lib/core/ui/` and `lib/core/theme/` against `docs/UI_REBUILD_PROMPT.md` section 4.
Theme roles, colour schemes and spacing scale are sound and kept. Components below need fixes.

### Existing screens
| Screen | Verdict |
|---|---|
| A01 splash, A02 sign-in, home, herd tab, add animal | Placeholders; none use AdaptiveScaffold. **Rewrite all in Step 2.** A02 signs in with phone + PIN, which breaks binding rule 7 (no phone OTP). A02 score 79–90 for a non-matching stub, so the score is coarse: always check the compare image. |
| Herd data | Uses the Isar repository directly. Needs `data/fake/` repositories behind `useFakeData`. |

### Tokens / typography
- Missing text styles: `hero` 44/700/1.1, `micro` 12/500.
- Missing colour: `card` (white light, `#18221E`-equivalent dark).
- Wrong sizes: inputHeight 56→60, keypadKey 72→64 (PIN 60), keypadMaxWidth 360→420, navBarHeight 76→80, pinDot 20→22, progressBar 8→10 (+6 thin), chip radius 10→12, dialog/sheet radius 24→28, keypad display radius 16→18.
- Missing sizes: avatars 36/40/44/52/56/80/88, bubble sizes 40/44/52/64, search 290×48, nav indicator 64×34, sidebar item 44, farm switcher 232×60, trial card 232×82, top bar 76, rail item pitch 76.

### Components
| Component | Differences from spec |
|---|---|
| Icons | Uses `Icons.*_rounded`; spec: Material Symbols Rounded, filled when selected/primary. |
| Shell compact | Order should be actions, sync, avatar (avatar 36 ring 3). No web-mobile hamburger. Nav label labelMedium→labelSmall, height 80, indicator 64×34. |
| Shell rail | bg surface→c1; no logo mark 36 or bottom avatar 40; items should be 76 apart. |
| Shell sidebar | bg surface→c1; nav items 48 radius 14→44 radius 22, label titleSmall→labelMedium; logo/switcher/trial card positions; search is a 360 TextField, spec is a 290×48 pill c2; no notification dot; content top padding 28; top bar 76. |
| Card | colour c0→`card` token; no child-gap helper. |
| MetricCard | bubble 48→40; unit titleMedium→titleSmall; caption bodyMedium→bodySmall; trend down/danger missing. |
| ActionTile | bubble 48→52; height 110/124; label titleMedium→titleSmall; no subtitle. |
| RecordTile | min 72→56; title titleMedium→titleSmall; subtitle bodyMedium→bodySmall; no trailing value + sub, no badge row; leading slot 56. |
| IconBubble | default 48; icon should be 52% of size, filled; size presets 40/44/52/64. |
| StatusBadge | labelMedium→labelSmall; height 26, padding 10, icon 16. |
| PersonAvatar | initials should be titleSmall at 36% of size; container kinds (primary/gold/info); ring 3. |
| Banner | radius 16→14, padding 16→14, icon 28→26, title titleMedium→titleSmall, message bodyMedium→bodySmall, action labelLarge right-aligned when width >480. |
| TrialCard | padding/size 232×82, 6 dp progress, copy check. |
| Chips | radius 10→12, labelLarge→labelMedium, 40 tall, unselected c0 border. |
| Segmented | track radius 16→24, height 48; thumb inset 4, radius 20, border; label titleSmall bold→labelMedium. |
| StepHeader | label should be centred labelMedium + optional Skip; 6 dp bar; title not part of header. |
| Keypad | gap 8→10; keys 72→64; unit headlineSmall→titleLarge; caret 2×40→3×46; backspace 28→30; caption missing. |
| PIN | dots 20/gap 24→22/gap 18; keys 72→60 pill, max width 340. |
| Read-back | detail bodyLarge→bodyMedium; avatar 88 with ring built in. |
| Sheet | handle 36×5 at 12, padding 24; wide dialog lacks close ×. |
| Dialog | bg c3→c1; bubble 72→64; title headlineSmall→titleLarge; message bodyLarge→bodyMedium; width 560→400; button gap 8→10; scrim 42%/60%. |
| Toast | 64 tall; text bodyLarge→bodyMedium; icon 28→24. |
| Celebration | title headlineMedium→headlineSmall; animation 240→230; optional summary card. |
| Charts | area 12%→14%; axis labels labelMedium→micro; highlight ring 7; target line missing. |
| Table | header c2→c1 radius 12, 44 tall; rows 72→60; first column titleSmall, others bodyMedium. |
| PrintedCardPreview | spec: white card, green header strip, avatar 64, tagNumber in primary, soft shadow. |
| Buttons | no helpers for tonal / danger / gold / neutral / large; side-by-side ≥420 rule. |
| Input | 60 tall, border 1.2, floating label labelSmall. |
| Missing | SearchField, ListCard, SectionLabel, HeroCard (tinted), OptionRow, LabeledProgress, PageDots, Timeline, split auth layout, centred layout, QR labels (E10). |
