---
name: taj-erp-offline-first
description: Use when working on the TAJ (تاج) Flutter ERP/POS codebase — enforces its offline-first data patterns, document state machine, accounting-ledger conventions, and existing Arabic RTL UI component set. Trigger on any task touching lib/core/demo, lib/data, lib/modules/*, or any request to add/modify a business document type (sales, purchases, expenses, stock, payments).
---

# TAJ ERP — Offline-First Development Skill

## Non-negotiable data rules

1. **Append-only ledgers.** Stock movements and accounting entries are never
   UPDATEd or DELETEd. A correction is a new reversing entry that references
   the original by id. This applies to any table named `*LedgerEntry` or
   `GLEntry`. If a task seems to require editing a historical entry, stop and
   propose a reversal entry instead.
2. **Document state machine.** Business documents (SalesInvoice,
   PurchaseInvoice, POSInvoice, JournalEntry, PaymentEntry) move through
   `draft -> submitted -> cancelled` only. `submitted` documents are
   immutable; `cancelled` reverses their ledger effects rather than deleting
   rows. Never implement a hard delete for a submitted document.
3. **IDs are UUIDs, not autoincrement**, for anything created client-side
   (offline devices must not collide on id generation).
4. **Every locally-created mutation writes a `SyncOutbox` row** in the same
   local transaction as the business write. Never write business data without
   also queuing its sync record.
5. **Repository layer, not direct DB calls from widgets.** Screens call a
   repository interface (e.g. `SalesRepository`), never `drift` tables or
   `DemoStore` directly. This keeps the local-first phase swappable for a
   networked backend later without touching UI code.

## UI/architecture conventions already established in this repo

- Shared UI comes from `lib/shared/widgets/taj_ui.dart`,
  `taj_table.dart`, `taj_filters.dart`, `app_shell.dart` — reuse these
  instead of building new one-off widgets for tables, filters, or page
  shells.
- Locale is `ar` with full RTL; number/currency formatting goes through
  `lib/core/format.dart` (`arNum`/`arDinar`) — never format numbers manually
  in a screen.
- Permissions are derived via `UserPermissions.forRole()` in
  `lib/core/user_role.dart`. New permission-gated actions must add a field
  there, not check `role == 'admin'` inline in a screen.
- Every `async` function that touches `context` after an `await` must guard
  with `if (!mounted) return;` (or `if (!context.mounted) return;` for
  static/top-level functions) immediately after the `await`.

## Workflow for adding a new business feature

1. Confirm which ledger(s) it touches (stock, GL, none).
2. Define the local `drift` table(s) mirroring the eventual backend schema —
   do not design a shape that only makes sense offline.
3. Add repository methods; wire the screen to the repository, never to the
   table directly.
4. Add the `SyncOutbox` write in the same transaction.
5. Run `flutter analyze` and the relevant widget tests before considering
   the task done.

## Out of scope for this skill

Server-side API design, PostgreSQL migrations, and the sync-pull protocol
live in the backend repo/plan (see `TAJ-Backend-Plan.md`), not here — this
skill only governs the Flutter client's local data and UI conventions.
