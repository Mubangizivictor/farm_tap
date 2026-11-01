# FarmTap UI rebuild — progress

Tracks every screen against its mockups (see `docs/UI_REBUILD_PROMPT.md`).
Cell legend: `—` not started · `wip` built, not matched · score (from `tool/compare_mockups.py`) once the compare image has been reviewed.
A screen is DONE only when Nav (ROUTES.md behaviour: button, iOS swipe, Android/browser back), Device (iPhone 16 Pro Max simulator, light + dark, via `tool/device_qa.py`), Small (375x667, 360x640, 1.3x text: no overflow) and A11y (labels, 48 dp targets) are ticked and the compare images look alike.
Columns: P = phone, T = tablet, D = web_desktop, M = web_mobile; L = light, K = dark.

| ID | Screen | Section | P·L | P·K | T·L | T·K | D·L | D·K | M·L | M·K | Score | Nav | Device | Small | A11y | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A01 | A01_splash | Launch & account | 97.4 | 98.0 | 99.2 | 99.4 | 99.4 | 99.5 | 97.4 | 98.0 | min 97.4 | ✓ | ✓ | ✓ | ✓ | done. Animation frame differs (stills taken mid-loop). |
| A02 | A02_sign_in | Launch & account | 95.6 | 96.1 | 96.9 | 97.6 | 97.4 | 98.1 | 95.6 | 96.1 | min 95.6 | ✓ | ✓ | ✓ | ✓ | done. Apple button shown on all platforms in goldens (iOS/web only at runtime). |
| A03 | A03_email_sign_in | Launch & account | 97.3 | 97.6 | 98.1 | 98.6 | 98.5 | 98.9 | 97.3 | 97.6 | min 97.3 | ✓ | ✓ | ✓ | ✓ | done. |
| A04 | A04_email_sign_up | Launch & account | 96.2 | 96.0 | 96.8 | 97.3 | 97.4 | 97.8 | 96.2 | 96.0 | min 96.0 | ✓ | ✓ | ✓ | ✓ | done. Mockup eye icon is "visibility_off" while hidden; A03 shows "visibility" — kept one rule: eye = show. Back arrow added on phone (navigation rule: every non-root screen), not in the mockup. |
| A05 | A05_forgot_password | Launch & account | 97.7 | 98.0 | 97.6 | 98.2 | 97.9 | 98.5 | 97.7 | 98.0 | min 97.6 | ✓ | ✓ | ✓ | ✓ | done. Toast copy includes the email ("Reset link sent to muhwezi.robert@gm…"); mockup shows a truncated placeholder. Back arrow added on phone (navigation rule: every non-root screen), not in the mockup. |
| A06 | A06_check_email | Launch & account | 96.5 | 96.7 | 98.8 | 98.8 | 99.1 | 99.1 | 95.1 | 95.5 | min 95.1 | ✓ | ✓ | ✓ | ✓ | done. |
| A07 | A07_farm_picker | Launch & account | 98.0 | 98.0 | 98.3 | 98.8 | 98.5 | 99.0 | 98.0 | 98.0 | min 98.0 | ✓ | ✓ | ✓ | ✓ | done. "Add another farm" opens onboarding once section B exists. |
| B01 | B01_onboard_language | Onboarding | 96.3 | 97.0 | 96.4 | 97.2 | 97.0 | 97.7 | 96.3 | 97.0 | min 96.3 | ✓ | ✓ | ✓ | ✓ | done. |
| B02 | B02_onboard_sector | Onboarding | 95.3 | 95.3 | 97.2 | 97.8 | 97.3 | 98.0 | 95.3 | 95.3 | min 95.3 | ✓ | ✓ | ✓ | ✓ | done. |
| B03 | B03_onboard_waitlist_sheet | Onboarding | 86.8 | 90.0 | 90.0 | 95.5 | 91.4 | 95.9 | 86.8 | 90.0 | min 86.8 | ✓ | ✓ | ✓ | ✓ | done. Phone score lower: the mockup sheet includes the home-indicator safe area (added on devices, not in goldens). Wide: dialog centred over the content column; mockup also swaps the panel animation. |
| B04 | B04_onboard_waitlist_done | Onboarding | 97.5 | 97.3 | 99.2 | 99.1 | 99.4 | 99.3 | 96.3 | 96.3 | min 96.3 | ✓ | ✓ | ✓ | ✓ | done. Back arrow added (navigation rule), not in the mockup. |
| B05 | B05_onboard_dairy_type | Onboarding | 97.1 | 97.2 | 97.4 | 98.0 | 97.8 | 98.3 | 97.1 | 97.2 | min 97.1 | ✓ | ✓ | ✓ | ✓ | done. |
| B06 | B06_onboard_farm_details | Onboarding | 95.8 | 95.9 | 97.5 | 97.9 | 98.0 | 98.3 | 95.8 | 95.9 | min 95.8 | ✓ | ✓ | ✓ | ✓ | done. |
| B07 | B07_onboard_contacts | Onboarding | 95.0 | 94.9 | 95.0 | 95.6 | 96.0 | 96.4 | 95.0 | 94.9 | min 94.9 | ✓ | ✓ | ✓ | ✓ | done. |
| B08 | B08_onboard_role | Onboarding | 97.9 | 98.1 | 97.6 | 98.3 | 98.0 | 98.6 | 97.9 | 98.1 | min 97.6 | ✓ | ✓ | ✓ | ✓ | done. |
| B09 | B09_onboard_first_staff | Onboarding | 96.5 | 96.5 | 97.1 | 97.6 | 97.7 | 98.1 | 96.5 | 96.5 | min 96.5 | ✓ | ✓ | ✓ | ✓ | done. |
| B10 | B10_onboard_trial_started | Onboarding | 94.0 | 94.5 | 98.1 | 98.2 | 98.5 | 98.7 | 92.7 | 93.5 | min 92.7 | ✓ | ✓ | ✓ | ✓ | done. Uses the real date; mockup date is Sat 7 Nov (trial ends 21 Nov). |
| C01 | C01_staff_tap_card | Staff unlock | 96.0 | 96.2 | 98.7 | 98.8 | 99.0 | 99.1 | 96.0 | 96.2 | min 96.0 | ✓ | — | ✓ | ✓ | done. Debug builds show 'Simulate tap (debug)' (no NFC in the UI phase). Device QA after section D. |
| C02 | C02_staff_card_number | Staff unlock | 88.4 | 89.8 | 94.5 | 95.6 | 95.6 | 96.5 | 88.4 | 89.8 | min 88.4 | ✓ | — | ✓ | ✓ | done. No decimal key on the card-number keypad (mockup shows '.', meaningless for a card number). Back arrow added (navigation rule). Device QA after section D (needs the lock action). |
| C03 | C03_staff_pin | Staff unlock | 97.3 | 97.5 | 99.1 | 99.2 | 99.3 | 99.4 | 97.3 | 97.5 | min 97.3 | ✓ | — | ✓ | ✓ | done. |
| C04 | C04_staff_pin_wrong | Staff unlock | 97.3 | 97.1 | 99.1 | 99.1 | 99.3 | 99.3 | 97.2 | 96.9 | min 96.9 | ✓ | — | ✓ | ✓ | done. |
| C05 | C05_nfc_unavailable | Staff unlock | 95.2 | 96.6 | 98.9 | 99.2 | 99.2 | 99.4 | 96.8 | 97.7 | min 95.2 | ✓ | — | ✓ | ✓ | done. |
| D01 | D01_home_owner | Home | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| D02 | D02_home_worker | Home | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| D03 | D03_alerts | Home | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| D04 | D04_sync_status_sheet | Home | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| D05 | D05_home_offline | Home | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| D06 | D06_notification_permission | Home | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E01 | E01_herd_list | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E02 | E02_herd_filter_sheet | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E03 | E03_animal_detail | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E04 | E04_add_animal | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E05 | E05_scan_qr | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E06 | E06_record_event_sheet | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E07 | E07_calf_born | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E08 | E08_confirm_death | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E09 | E09_head_count | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| E10 | E10_print_qr_labels | Herd | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F01 | F01_milk_today | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F02 | F02_milk_pick_cow | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F03 | F03_milk_keypad | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F04 | F04_milk_read_back | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F05 | F05_milk_saved | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F06 | F06_treated_cow_warning | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F07 | F07_milk_herd_total | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F08 | F08_milk_use_split | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F09 | F09_milk_sales | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| F10 | F10_milk_trends | Milk | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G01 | G01_centre_home | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G02 | G02_centre_tap_card | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G03 | G03_centre_delivery_keypad | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G04 | G04_centre_delivery_read_back | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G05 | G05_centre_delivery_saved | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G06 | G06_centre_farmers | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G07 | G07_centre_farmer_detail | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G08 | G08_centre_close_session | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G09 | G09_centre_statements | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G10 | G10_centre_payment_sheet | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G11 | G11_centre_sms_preview | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G12 | G12_centre_quality_test | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| G13 | G13_centre_reconciliation | Collection centre | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| H01 | H01_health_home | Health | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| H02 | H02_add_treatment | Health | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| H03 | H03_treatment_saved | Health | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| H04 | H04_drug_stock | Health | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| H05 | H05_health_schedule | Health | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| H06 | H06_withdrawal_list | Health | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| I01 | I01_feed_stock | Feeding | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| I02 | I02_record_feeding | Feeding | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| I03 | I03_feed_purchase_sheet | Feeding | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| J01 | J01_breeding_calendar | Breeding | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| J02 | J02_record_service_sheet | Breeding | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| J03 | J03_pregnancy_confirmed | Breeding | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| K01 | K01_staff_list | Workers | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| K02 | K02_staff_detail | Workers | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| K03 | K03_assign_card | Workers | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| K04 | K04_attendance | Workers | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| K05 | K05_tasks | Workers | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| K06 | K06_wages | Workers | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| L01 | L01_money_overview | Money | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| L02 | L02_add_expense | Money | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| L03 | L03_reports | Money | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| L04 | L04_whatsapp_report_preview | Money | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M01 | M01_subscription | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M02 | M02_pay_mobile_money | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M03 | M03_payment_confirmed | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M04 | M04_trial_ending_popup | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M05 | M05_read_only_locked | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| N01 | N01_more_menu | Settings | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| N02 | N02_settings | Settings | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| N03 | N03_farm_profile | Settings | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| N04 | N04_language_sheet | Settings | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| N05 | N05_help_support | Settings | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| N06 | N06_sign_out_confirm | Settings | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| N07 | N07_delete_account | Settings | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| O01 | O01_admin_payments | Admin (Victorbee) | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| P01 | P01_empty_herd | System states | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| P02 | P02_error_state | System states | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| P03 | P03_camera_permission | System states | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| P04 | P04_manager_pin_required | System states | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| P05 | P05_offline_saved_toast | System states | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| P06 | P06_sync_done_toast | System states | — | — | — | — | — | — | — | — |  | — | — | — | — |  |

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

## UI kit rebuild (Step 1 result)

All components in the audit table were fixed or rewritten to section 4. Icons are Material Symbols Rounded (`fill: 1` for filled).
New: `buttons.dart` (FarmTapButton kinds, ButtonPair, TextAction), `layouts.dart` (SplitAuthLayout, CenteredLayout),
FarmTapCard, CardHeader, SectionLabel, HeroCard, ListCard, OptionRow, Timeline, FarmTapChip, FarmTapProgress, PageDots,
SearchField, SheetFrame / SheetDialogFrame / DialogFrame / SheetTitle, ToastContent, BarAction, FarmTapLogo / FarmTapLogoMark,
FarmTapFab, FarmTapPlatform. Still to build with their screens: QR labels (E10).

`/dev/gallery` goldens: `test/goldens/UI_kit_gallery_<phone|tablet|desktop>_<mode>.png` (full catalogue) and
`test/goldens/gallery/<ff>/<mode>/D01_home_owner.png` (first screenful = D01 replica), compared with the D01 mockup:

| Form factor | Light | Dark | Notes |
|---|---|---|---|
| phone | 96.5 | 96.5 | Trial message wraps one word earlier (font metrics). |
| tablet | 93.5 | 92.6 | Sidebar shown: 1194 dp is "expanded" in UX_SPEC; the tablet mockups show the rail. **Open question.** |
| web_desktop | 96.2 | 96.2 | |
| web_mobile | 96.5 | 96.5 | Same as phone (mockup keeps the bottom bar). |
