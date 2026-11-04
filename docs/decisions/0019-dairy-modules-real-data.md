# 0019 — Dairy modules on real data, and the small features they were missing

- Status: accepted (2026-11-03): owner asked for a full check of every dairy module and to "add the small features that you know they are missing even when I didn't tell you"
- Date: 2026-11-03
- Decided by: Mubangizi Victor (owner)
- Builds on: 0014 (offline journal and sync). Every record below is saved on the phone first and syncs later.
- Not in scope (other threads): ID cards, card scan station, staff sign-in and permissions (0015 cards), free WhatsApp/SMS (0015 SMS), web app (0017), one farm per account (0018).

## Audit (3 Nov 2026, real-data mode `useFakeData = false`)
| Module | Before | Now |
|---|---|---|
| Milk (F01–F10) | Sales list was sample text; no way to add a sale or mark it paid; only today. | Add sale (buyer remembered), tap to mark paid/unpaid, pick any past day, real produced/sold totals, PDF or spreadsheet export. |
| Herd (E01–E08) | Could not edit an animal; groups and breeds fixed; "Sold" did nothing; tag scan was a placeholder. | Edit animal, photo, custom group/breed, status (milking/dry/heifer), duplicate-tag check, QR tag scan, sell an animal (income recorded), name the calf. |
| Money and reports (L01–L04) | Reports and downloads were placeholders; no other income; no receipts. | Month view, other income (animal sale, manure, calf, hire), receipt photos, delete own expense, real monthly report and "export all", daily report phone and WhatsApp send. |
| Health (H01–H06) | No photo or note; drug stock could not be restocked or counted; jobs could not be ticked. | Treatment photo and note, custom "given by", drug "bought more" (vet expense) and "count", jobs marked done, overdue shown. |
| Feeding (I01–I04) | Stock only from purchases; four feeds. | Stock count corrects what is left; napier, hay, cotton seed cake and brewers' waste added. |
| Home | Sample worker name; "left to feed" and "treatments due" were fixed numbers. | Real groups left to feed and treatments due. |
| Breeding (J01–J03) | Straw and cost always "Friesian 4421 / 35,000"; technician list fixed; check saved as a sample vet. | Straw and technician picked from past ones or typed; last AI cost prefilled; check saved as the person using the phone; message when there are no cows yet. |
| Milk suppliers (G01–G13) | Call, edit and download buttons did nothing; price fixed at 1,100; any PIN closed a session; list did not refresh after adding. | Call (copies the number if the phone cannot call), edit farmer with SMS receipts on/off, price per litre (amounts owed follow it), manager PIN checked (owner closes when there is no manager), farmers and statements download, lists refresh. |
| Workers (K01–K06) | Attendance kept in memory only; activity log "coming soon". | Left to the cards thread, which already saves attendance (0015). |

## Decision
1. **Photos without paying first.** Photos (animals, receipts, treatments) are compressed and kept on the phone (`core/media/photo_store.dart`) and queued. They upload to Firebase Storage by themselves once Storage is switched on (Blaze plan); `storage.rules` only lets farm members write images under 5 MB to their own farm.
2. **Exports are made on the phone** (`core/export/table_export.dart`): every list shares as PDF or spreadsheet (CSV, opens in Excel/Sheets) with no server, so they work offline.
3. **Paid marks on milk sales** live in their own collection (`milkSalePayments`, last write wins) because `milkSales` is append-only.
4. **Price per litre** for centres is saved in `settings/centrePrice`.
5. **Income** other than milk is the `income` collection (`IncomeSource`): animal sale, manure, calf sale, hire, other. Selling an animal records it automatically.

## Small features added without being asked
- Milk: buyers remembered; unpaid sales stay listed until paid; percentage badges per cow; tap a cow from the milk list.
- Herd: duplicate tag warning; QR tag scan opens milking or treatment directly (`/herd/scan?for=milk|health`).
- Money: tap an expense to see its receipt or delete it; month arrows.
- Health: overdue jobs marked; drug reorder level.
- Feeding: count stock to correct what is left.
- Breeding: past straws and technicians as a pick list with custom entry.
- Centre: phone number copied when calling is not possible; SMS receipts switch per farmer.

## Owner to do
- Turn on Firebase Storage (Blaze) when ready, then `firebase deploy --only firestore:rules,storage`. Until then photos stay on the phone that took them.
