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
| C01 | C01_staff_tap_card | Staff unlock | 96.0 | 96.2 | 98.7 | 98.8 | 99.0 | 99.1 | 96.0 | 96.2 | min 96.0 | ✓ | ✓ | ✓ | ✓ | done. Debug builds show 'Simulate tap (debug)' (no NFC in the UI phase). Device QA after section D. |
| C02 | C02_staff_card_number | Staff unlock | 88.4 | 89.8 | 94.5 | 95.6 | 95.6 | 96.5 | 88.4 | 89.8 | min 88.4 | ✓ | ✓ | ✓ | ✓ | done. No decimal key on the card-number keypad (mockup shows '.', meaningless for a card number). Back arrow added (navigation rule). Device QA after section D (needs the lock action). |
| C03 | C03_staff_pin | Staff unlock | 97.2 | 97.4 | 99.1 | 99.2 | 99.3 | 99.4 | 97.3 | 97.4 | min 97.2 | ✓ | ✓ | ✓ | ✓ | done. |
| C04 | C04_staff_pin_wrong | Staff unlock | 97.3 | 97.1 | 99.1 | 99.1 | 99.3 | 99.3 | 97.2 | 96.9 | min 96.9 | ✓ | ✓ | ✓ | ✓ | done. |
| C05 | C05_nfc_unavailable | Staff unlock | 95.2 | 96.6 | 98.9 | 99.2 | 99.2 | 99.4 | 96.8 | 97.7 | min 95.2 | ✓ | ✓ | ✓ | ✓ | done. |
| D01 | D01_home_owner | Home | 96.0 | 96.0 | 96.3 | 96.0 | 96.3 | 96.3 | 96.0 | 96.0 | min 96.0 | ✓ | ✓ | ✓ | ✓ | done. Greeting follows the clock; staff avatar tap locks the phone (goes to C01). |
| D02 | D02_home_worker | Home | 95.6 | 95.6 | 96.6 | 96.2 | 97.2 | 97.1 | 95.6 | 95.6 | min 95.6 | ✓ | ✓ | ✓ | ✓ | done. |
| D03 | D03_alerts | Home | 93.4 | 93.4 | 97.0 | 97.0 | 97.2 | 97.2 | 93.4 | 93.4 | min 93.4 | ✓ | ✓ | ✓ | ✓ | done. |
| D04 | D04_sync_status_sheet | Home | 87.5 | 90.4 | 92.9 | 95.5 | 91.5 | 95.3 | 87.5 | 90.4 | min 87.5 | ✓ | ✓ | ✓ | ✓ | done. Background home shows the trial banner (mockup sample omits it); sheet rows 76 apart. |
| D05 | D05_home_offline | Home | 95.9 | 95.9 | 96.4 | 96.1 | 96.3 | 96.3 | 95.9 | 95.9 | min 95.9 | ✓ | ✓ | ✓ | ✓ | done. |
| D06 | D06_notification_permission | Home | 95.2 | 96.0 | 93.6 | 95.8 | 93.2 | 95.8 | 95.2 | 96.0 | min 93.2 | ✓ | ✓ | ✓ | ✓ | done. Shown after the first saved record (wired with section F). |
| E01 | E01_herd_list | Herd | 93.9 | 94.6 | 95.7 | 96.0 | 96.8 | 96.8 | 93.8 | 94.4 | min 93.8 | ✓ | ✓ | ✓ | ✓ | done. |
| E02 | E02_herd_filter_sheet | Herd | 90.7 | 92.6 | 93.2 | 96.1 | 92.0 | 96.1 | 90.6 | 92.6 | min 90.6 | ✓ | ✓ | ✓ | ✓ | done. Filter count comes from the 8 sample rows (mockup: 18 of 48). |
| E03 | E03_animal_detail | Herd | 93.1 | 93.3 | 97.5 | 97.7 | 96.2 | 96.0 | 93.1 | 93.3 | min 93.1 | ✓ | ✓ | ✓ | ✓ | done. |
| E04 | E04_add_animal | Herd | 94.3 | 94.7 | 96.0 | 96.4 | 96.8 | 96.9 | 94.3 | 94.7 | min 94.3 | ✓ | ✓ | ✓ | ✓ | done. |
| E05 | E05_scan_qr | Herd | 95.8 | 95.4 | 95.9 | 97.2 | 96.7 | 96.8 | 95.8 | 95.4 | min 95.4 | ✓ | ✓ | ✓ | ✓ | done. Viewfinder without live camera in the UI phase (mobile_scanner wiring with functionality). |
| E06 | E06_record_event_sheet | Herd | 91.6 | 94.3 | 94.9 | 96.8 | 93.7 | 96.7 | 91.6 | 94.3 | min 91.6 | ✓ | ✓ | ✓ | ✓ | done. |
| E07 | E07_calf_born | Herd | 91.7 | 92.9 | 91.7 | 95.1 | 89.9 | 95.2 | 91.7 | 92.9 | min 89.9 | ✓ | ✓ | ✓ | ✓ | done. |
| E08 | E08_confirm_death | Herd | 92.5 | 94.2 | 94.1 | 96.1 | 93.1 | 95.8 | 92.5 | 94.2 | min 92.5 | ✓ | ✓ | ✓ | ✓ | done. |
| E09 | E09_head_count | Herd | 96.9 | 97.0 | 97.4 | 97.2 | 98.0 | 97.9 | 96.9 | 97.0 | min 96.9 | ✓ | ✓ | ✓ | ✓ | done. |
| E10 | E10_print_qr_labels | Herd | 87.5 | 79.3 | 94.9 | 90.2 | 95.8 | 95.6 | 87.5 | 79.3 | min 79.3 | ✓ | ✓ | ✓ | ✓ | done. Real scannable QR codes (farmtap:animal:<tag>); Print / Share PDF via printing. |
| F01 | F01_milk_today | Milk | 94.2 | 95.1 | 95.1 | 95.4 | 96.7 | 96.8 | 94.0 | 94.9 | min 94.0 | ✓ | ✓ | ✓ | ✓ | done. Adds a Milk tools row (quick total, use, sales, trends) so F07-F10 are reachable. |
| F02 | F02_milk_pick_cow | Milk | 91.9 | 91.8 | 97.2 | 97.2 | 97.0 | 96.9 | 91.9 | 91.8 | min 91.8 | ✓ | ✓ | ✓ | ✓ | done. |
| F03 | F03_milk_keypad | Milk | 95.3 | 95.6 | 97.7 | 97.9 | 97.7 | 97.7 | 95.3 | 95.6 | min 95.3 | ✓ | ✓ | ✓ | ✓ | done. |
| F04 | F04_milk_read_back | Milk | 88.6 | 91.7 | 96.2 | 97.8 | 94.3 | 97.1 | 88.6 | 91.7 | min 88.6 | ✓ | ✓ | ✓ | ✓ | done. Mockup's background screen omits the 'How many litres?' row shown on F03. |
| F05 | F05_milk_saved | Milk | 92.0 | 92.9 | 95.5 | 97.6 | 93.4 | 96.9 | 92.0 | 92.9 | min 92.0 | ✓ | ✓ | ✓ | ✓ | done. Auto-advances after 2 s; next cow is the next unrecorded one. |
| F06 | F06_treated_cow_warning | Milk | 95.2 | 96.0 | 95.8 | 97.2 | 94.6 | 96.7 | 95.2 | 96.0 | min 94.6 | ✓ | ✓ | ✓ | ✓ | done. |
| F07 | F07_milk_herd_total | Milk | 96.9 | 97.2 | 96.5 | 96.5 | 98.2 | 98.2 | 96.9 | 97.2 | min 96.5 | ✓ | ✓ | ✓ | ✓ | done. |
| F08 | F08_milk_use_split | Milk | 96.2 | 96.6 | 93.5 | 94.3 | 97.3 | 97.5 | 96.2 | 96.6 | min 93.5 | ✓ | ✓ | ✓ | ✓ | done. |
| F09 | F09_milk_sales | Milk | 94.7 | 95.0 | 97.5 | 97.6 | 98.1 | 98.1 | 94.7 | 95.0 | min 94.7 | ✓ | ✓ | ✓ | ✓ | done. |
| F10 | F10_milk_trends | Milk | 96.0 | 96.2 | 96.8 | 97.0 | 97.5 | 97.6 | 96.0 | 96.2 | min 96.0 | ✓ | ✓ | ✓ | ✓ | done. |
| G01 | G01_centre_home | Collection centre | 95.6 | 96.0 | 93.0 | 93.8 | 96.2 | 96.5 | 95.6 | 96.0 | min 93.0 | ✓ | ✓ | ✓ | ✓ | done. |
| G02 | G02_centre_tap_card | Collection centre | 95.9 | 96.3 | 98.3 | 98.5 | 98.0 | 98.0 | 95.9 | 96.3 | min 95.9 | ✓ | ✓ | ✓ | ✓ | done. |
| G03 | G03_centre_delivery_keypad | Collection centre | 95.9 | 96.3 | 95.8 | 96.2 | 97.0 | 97.0 | 95.9 | 96.3 | min 95.8 | ✓ | ✓ | ✓ | ✓ | done. |
| G04 | G04_centre_delivery_read_back | Collection centre | 90.1 | 91.7 | 93.5 | 96.1 | 92.6 | 95.9 | 90.1 | 91.7 | min 90.1 | ✓ | ✓ | ✓ | ✓ | done. |
| G05 | G05_centre_delivery_saved | Collection centre | 95.9 | 96.2 | 98.4 | 98.4 | 98.0 | 97.9 | 96.1 | 96.3 | min 95.9 | ✓ | ✓ | ✓ | ✓ | done. |
| G06 | G06_centre_farmers | Collection centre | 93.1 | 93.2 | 95.7 | 95.8 | 96.6 | 96.6 | 93.0 | 93.1 | min 93.0 | ✓ | ✓ | ✓ | ✓ | done. |
| G07 | G07_centre_farmer_detail | Collection centre | 93.7 | 93.8 | 96.5 | 96.6 | 97.4 | 97.3 | 93.7 | 93.8 | min 93.7 | ✓ | ✓ | ✓ | ✓ | done. |
| G08 | G08_centre_close_session | Collection centre | 94.4 | 95.9 | 93.4 | 96.3 | 93.2 | 96.8 | 94.4 | 95.9 | min 93.2 | ✓ | ✓ | ✓ | ✓ | done. |
| G09 | G09_centre_statements | Collection centre | 91.5 | 92.0 | 93.1 | 93.1 | 94.8 | 94.8 | 91.4 | 91.8 | min 91.4 | ✓ | ✓ | ✓ | ✓ | done. |
| G10 | G10_centre_payment_sheet | Collection centre | 93.5 | 93.3 | 88.9 | 90.7 | 91.9 | 93.1 | 93.5 | 93.3 | min 88.9 | ✓ | ✓ | ✓ | ✓ | done. |
| G11 | G11_centre_sms_preview | Collection centre | 86.2 | 88.0 | 96.7 | 96.7 | 95.6 | 95.8 | 86.2 | 88.0 | min 86.2 | ✓ | ✓ | ✓ | ✓ | done. |
| G12 | G12_centre_quality_test | Collection centre | 87.2 | 88.3 | 94.7 | 96.5 | 93.0 | 95.8 | 87.2 | 88.3 | min 87.2 | ✓ | ✓ | ✓ | ✓ | done. |
| G13 | G13_centre_reconciliation | Collection centre | 93.3 | 92.0 | 92.7 | 93.2 | 94.6 | 95.3 | 93.3 | 92.0 | min 92.0 | ✓ | ✓ | ✓ | ✓ | done. |
| H01 | H01_health_home | Health | 96.1 | 96.6 | 96.8 | 97.0 | 97.3 | 97.4 | 95.9 | 96.5 | min 95.9 | ✓ | ✓ | ✓ | ✓ | done. |
| H02 | H02_add_treatment | Health | 93.1 | 93.0 | 91.1 | 90.9 | 92.5 | 92.3 | 93.1 | 93.0 | min 90.9 | ✓ | ✓ | ✓ | ✓ | done. |
| H03 | H03_treatment_saved | Health | 92.0 | 93.4 | 92.0 | 95.3 | 90.6 | 95.3 | 92.0 | 93.4 | min 90.6 | ✓ | ✓ | ✓ | ✓ | done. |
| H04 | H04_drug_stock | Health | 96.3 | 96.3 | 97.5 | 97.2 | 98.0 | 98.0 | 96.3 | 96.3 | min 96.3 | ✓ | ✓ | ✓ | ✓ | done. |
| H05 | H05_health_schedule | Health | 96.7 | 96.7 | 97.7 | 97.7 | 98.0 | 97.9 | 96.7 | 96.7 | min 96.7 | ✓ | ✓ | ✓ | ✓ | done. |
| H06 | H06_withdrawal_list | Health | 94.3 | 94.2 | 97.2 | 97.0 | 97.6 | 97.5 | 94.3 | 94.2 | min 94.2 | ✓ | ✓ | ✓ | ✓ | done. |
| I01 | I01_feed_stock | Feeding | 94.5 | 94.9 | 97.0 | 96.7 | 97.4 | 97.4 | 94.3 | 94.8 | min 94.3 | ✓ | ✓ | ✓ | ✓ | done. Stock, days left and cost per litre derived from records. |
| I02 | I02_record_feeding | Feeding | 94.1 | 94.1 | 97.3 | 97.0 | 97.1 | 96.9 | 94.1 | 94.1 | min 94.1 | ✓ | ✓ | ✓ | ✓ | done. Golden types 1.5 as in mockup. Back arrow asks Discard changes?. |
| I03 | I03_feed_purchase_sheet | Feeding | 89.2 | 91.1 | 90.0 | 93.5 | 89.9 | 94.5 | 89.1 | 91.1 | min 89.1 | ✓ | ✓ | ✓ | ✓ | done. Backdrop differs: the I03 mockup shows a low-stock banner behind the sheet, while I01's own mockup shows the feed-cost card; I01's own mockup wins (main cause of the lower score). Save has read-back (money); purchase creates its expense in the money repository (DAIRY-FEED-02). Dirty sheet asks Discard changes? on drag/scrim/back. |
| J01 | J01_breeding_calendar | Breeding | 95.7 | 96.2 | 96.2 | 96.5 | 97.1 | 97.2 | 95.5 | 96.0 | min 95.5 | ✓ | ✓ | ✓ | ✓ | done. Pregnant/calving/check counts derived from breeding records (herd pregnant count and home calving alert read the same records). To-do lists 3 items (2 checks + Rwemera serve): data has 2 checks due as the metric says. Kasheshe "Served 12 Sep · check from 7 Nov" (mockup 2 Oct/2 Nov conflicts with J02 56-day rule). |
| J02 | J02_record_service_sheet | Breeding | 87.1 | 89.2 | 89.5 | 93.0 | 89.4 | 94.0 | 87.0 | 89.1 | min 87.0 | ✓ | ✓ | ✓ | ✓ | done. Rules from J02: check +56 d (2 Jan), calving +280 d (14 Aug 2027). Cost read-back; expense recorded in money repository (breeding). Mockup backdrop shows a heat banner; J01 keeps its own mockup. All mockup fields present (Heat seen/Served/AI segmented control, semen/straw, technician, date, cost, check-reminder info box); the sheet is only shorter, so it sits lower on screen, which is the score gap - accepted. |
| J03 | J03_pregnancy_confirmed | Breeding | 92.5 | 93.6 | 93.2 | 96.0 | 91.3 | 95.7 | 92.3 | 93.6 | min 91.3 | ✓ | ✓ | ✓ | ✓ | done. Data wins: the check due is Kasheshe (calving 19 June, dry off 20 Apr), not Kyasiimire (calves in 6 days). Dry off = 60 d before calving (mockup 15 Sep = 59 d). |
| K01 | K01_staff_list | Workers | 93.6 | 93.8 | 96.6 | 96.7 | 96.8 | 96.9 | 93.5 | 93.7 | min 93.5 | ✓ | ✓ | ✓ | ✓ | done. In/Not in from attendance; vet visits (not on shift). Attendance/Tasks/Wages icons in the bar (no entry point in any mockup; see Gaps). |
| K02 | K02_staff_detail | Workers | 96.2 | 96.3 | 96.9 | 97.0 | 97.7 | 97.7 | 96.2 | 96.3 | min 96.2 | ✓ | ✓ | ✓ | ✓ | done. Days this month and balance owed from records. Milk records shows a dash (see Gaps). |
| K03 | K03_assign_card | Workers | 95.1 | 93.9 | 97.0 | 96.0 | 97.6 | 96.7 | 95.1 | 93.9 | min 93.9 | ✓ | ✓ | ✓ | ✓ | done. Next blank printed card (0207); NFC, debug Simulate tap, and Type card number (decision 0006) - full flow device-checked without NFC. |
| K04 | K04_attendance | Workers | 92.0 | 92.7 | 93.2 | 94.2 | 95.9 | 96.2 | 92.0 | 92.7 | min 92.0 | ✓ | ✓ | ✓ | ✓ | done. Clock in/out by card or typed number; 4 of 5 on shift. |
| K05 | K05_tasks | Workers | 94.8 | 95.1 | 97.4 | 97.5 | 97.6 | 97.6 | 94.8 | 95.1 | min 94.8 | ✓ | ✓ | ✓ | ✓ | done. Today / This week / Done from task records; Home worker tasks read the same records. |
| K06 | K06_wages | Workers | 92.5 | 92.5 | 96.4 | 96.5 | 96.6 | 96.6 | 92.5 | 92.5 | min 92.5 | ✓ | ✓ | ✓ | ✓ | done. Totals summed from wages and advance/payment records; pay and advance have read-back and record wage expenses in core/money. |
| L01 | L01_money_overview | Money | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| L02 | L02_add_expense | Money | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| L03 | L03_reports | Money | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| L04 | L04_whatsapp_report_preview | Money | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M01 | M01_subscription | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M02 | M02_pay_mobile_money | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M03 | M03_payment_confirmed | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M04 | M04_trial_ending_popup | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| M05 | M05_read_only_locked | Subscription | — | — | — | — | — | — | — | — |  | — | — | — | — |  |
| N01 | N01_more_menu | Settings | 95.2 | 95.2 | 97.0 | 97.0 | 97.8 | 97.8 | 95.0 | 95.1 | min 95.0 | ✓ | ✓ | ✓ | ✓ | done. Feeding/Breeding/Workers/Money/Reports/Settings/Subscription/Help push from /more with back arrow; unbuilt ones show Coming soon. Lock phone -> /unlock; Sign out asks first (N06 styles it later). Profile -> Settings, Cards -> Workers (no route in ROUTES.md; see Gaps). |
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

## Data over mockup — Section J

| Screen | Mockup text | Shown (from data) | Why |
|---|---|---|---|
| J01 To do | Kasheshe "Served 2 Oct · check from 2 Nov" | "Served 12 Sep · check from 7 Nov" | One check rule (56 days after service, from J02's 7 Nov -> 2 Jan). 2 Oct + 56 d would not be due yet. |
| J01 To do | 2 rows (Kasheshe, Rwemera) | 3 rows (Kasheshe, Nyakato, Rwemera) | The "Check pregnancy 2" card needs two checks due; the list shows both. |
| J02 Date | "Today 7:30 am" | "Today 8:41 am" (device) / "6:52 am" (golden clock) | Date defaults to now from the injected Clock. |
| J02 backdrop | "Rwemera showed heat yesterday" banner | J01 as in its own mockup | J01's own mockup wins (as I03). |
| J03 | "Kyasiimire is pregnant! Expected calving: 13 November" | "Kasheshe is pregnant! Expected calving: 19 June" | Kyasiimire calves in 6 days, so she cannot be the cow getting a pregnancy check; Kasheshe is the check due. |
| J03 Served | "6 Feb · AI · Jersey 1180" | "12 Sep · AI · Friesian 4421" | Kasheshe's service record. |
| J03 Checked by | "Dr. Kamugisha" | "Dr. Kamugisha Ivan" | Full name from the vet list (same vet as H02). |
| J03 Dry off | "15 Sep" (59 d before 13 Nov) | 60 days before calving ("20 Apr" for Kasheshe) | One dry-off rule (60 d). |

## Data over mockup — Section K

| Screen | Mockup text | Shown (from data) | Why |
|---|---|---|---|
| K04 / Home D01 | "4 of 6 in" (K04), "5/6" (D01) | "4 of 5 in", "4/5" | One rule from K01: 5 staff on shifts, the vet visits ("Visits Tue"); 4 clocked in today. |
| K01 phone | Vet row trailing (none) | no In/Out; table "Visits" | Vet has no shift; next visit day is not modelled yet. |
| K02 | "Days this month 24" | 7 (Amos) | It is 7 November; counted from clock-in records. |
| K02 | "Card 0201" (Amos) | "Card 0142" | Amos unlocks with 0142 in C01-C04 (same staff records). |
| K02 | "Milk records 312" | "—" | Milk records do not store who recorded them yet (see Gaps). |
| K06 | "Wages this month UGX 1.62M" | "UGX 1.52M" | Sum of the five wages listed on the same screen. |
| K05 | "Done 9:12" | "Done 6:30" | Sample day is 8:41 am (6:52 in goldens); a task cannot be done in the future. |
| D02 worker home | 2 tasks (heifers, clean milking area) | 1 task (heifers) | K05 assigns "Clean milking area" to Rita, not Amos. |

## Gaps (not built; ask before building)

| Item | Status |
|---|---|
| DAIRY-BRD-05 Calving creates calf linked to dam | Covered by E07 (calf born): calf created with motherTag; since Section J it also ends the pregnancy in breeding (test). No separate breeding screen needed. |
| N01 Profile card target | No mockup/route for a profile screen; opens Settings (N02). Kept by decision. |
| N01 Cards tile target | No route in ROUTES.md; opens Workers (staff cards are assigned per worker in K03; Section K has no card list). Kept by decision. |
| N06 sign-out | When Section N is built: show the unsynced count and offer 'Sync, then sign out' / 'Sign out anyway'. Current N01 sign-out is a plain confirm. |
| K01 entry to K04/K05/K06 | No mockup shows how to reach Attendance, Tasks, Wages; three bar icons on K01 added. |
| K01 Add worker, K02 Edit, What X can do, Activity log | No mockup screens; show "Coming soon" toast. |
| K02 Milk records count | Needs recordedBy on milk records (backend phase); shows "—". |
