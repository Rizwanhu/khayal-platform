# Khayal (خیال) — Agile Delivery Plan (Phase-by-Phase, Start → MVP → Continuous Delivery)

**Working model**: Agile (Scrum-style) with **time-boxed sprints** (recommended **2 weeks**), continuous refinement, and a **living backlog** for new features after MVP.  
**Source of truth**: `Khayal_SRS_v1.1_Updated.pdf` (MVP v1.1) + architecture blueprint `SYSTEM_ARCHITECTURE.md`.  
**Mindset**: Senior engineering lead—ship safely, prove reliability (alarms/offline), and keep security/privacy non-negotiable.

---

## How to read this document (operating rules)

### Sprint shape (every sprint, without exception)
- **Sprint Goal**: one sentence outcome.
- **Backlog items**: epics → stories → **micro-tasks** (each task ≤ 1 day ideally).
- **Definition of Ready (DoR)**: story has acceptance criteria, UX reference, data contract, test notes, risk flags.
- **Definition of Done (DoD)**: code reviewed, tests added/updated, docs updated, feature flagged if risky, demoable build.
- **Ceremonies**:
  - **Sprint Planning** (2h): pick scope, cut scope if needed, identify dependencies.
  - **Daily standup** (15m): blockers, alarm reliability, sync/offline health.
  - **Sprint Review** (1h): demo on real devices (Android + iOS).
  - **Retro** (45m): process + technical debt decisions.
  - **Backlog Refinement** (1–2h mid-sprint): prep next sprint.

### Traceability convention
Each story should include tags like:
- **FR-*** / **NFR-*** / **SCR-*** from the SRS
- **ARCH** references (modules/files in `SYSTEM_ARCHITECTURE.md`)

### “Enterprise” quality gates (lightweight but real)
- **Gate A — Safety**: reminders still fire after reboot / app killed / offline.
- **Gate B — Security**: authz checks on every patient-scoped endpoint; OTP rules enforced.
- **Gate C — Privacy**: data minimization + policy links + no surprises permissions.
- **Gate D — UX**: Urdu RTL + font scaling + 48dp targets verified on devices.

---

## Phase 0 — Project bootstrap (Week 0, pre-Sprint 1)

**Goal**: Create a professional delivery machine before feature work explodes.

### Deliverables
- **Team agreements**: roles (PM/PO, Tech lead, Mobile, Backend, UX, QA), decision log.
- **Tooling**:
  - Issue tracker (Jira/Linear/GitHub Projects) with **epics** matching sections below
  - CI placeholder pipeline (even if it only runs lint/tests on hello-world)
- **Repositories** (mono-repo recommended):
  - `apps/mobile`
  - `services/api`
  - `docs/`
- **Branching**: trunk-based or GitFlow-lite; **protected main**; PR template w/ security checklist.
- **Environments**: `dev`, `staging`, `prod` (can be “cheap staging” early, but must exist as a concept).
- **Secrets**: store in vault/CI secrets; **no secrets in repo**.

### Micro-tasks
- Create **epic list** mapped to SRS sections (Auth, Meds, Reminders, Escalation, Logs, Dashboard, i18n/RTL, Offline, Security, Permissions).
- Create **test device matrix** (Android 12/13/14 + iOS versions available to you).
- Create **“Alarm Reliability” test checklist** (boot, battery optimization, DND—where applicable).

**Exit criteria**: Backlog is structured; everyone knows where tasks live; CI runs something on every PR.

---

## Phase 1 — Discovery → UX/HCI foundation (Sprints 1–2)

**Goal**: Turn SRS into **screen-level UX**, flows, and measurable acceptance tests *before* deep implementation.

### Sprint 1 — UX blueprint + IA (information architecture)

#### Epics / stories (micro-detail)
**E1 — Screen inventory + navigation map (SCR-001..017)**
- Build Figma (or equivalent) for every screen listed in SRS.
- Define navigation graph:
  - Patient path: Splash → Lang → Role → Home → Confirmation → History
  - Caregiver path: Splash → Lang → Role → Register → Patient profile → Dashboard → Manage meds → Settings

**Micro-tasks**
- Wireframes with **Urdu-first** typography rules (Minimum 18sp body; headings ≥24sp).  
  **Maps to**: Design rules §8.1, FR-L10N-*, SCR-016
- RTL layout prototypes for Urdu screens (mirrored spacing, icons, back affordances).  
  **Maps to**: FR-L10N-02, §8.2
- Accessibility review pass: contrast, tap targets, no swipe-only interactions.  
  **Maps to**: FR-L10N-06/07, §8.1 “no swipe gestures”
- Notification UX copy deck (Urdu polite family tone + English).  
  **Maps to**: §8.4, FR-ESC-03 content needs

**E2 — Critical user journeys (testable)**
- **J1**: First-time caregiver sets up patient + meds + confirms schedule published to patient device (conceptually).  
  **Maps to**: FR-AUTH-04, FR-MED-01/04, FR-MED-05
- **J2**: Reminder fires → user taps Taken in ≤2 taps (NFR-USE-02).  
  **Maps to**: FR-REM-02/06, NFR-USE-02
- **J3**: Missed dose escalation timeline 0→15→30 with expected notifications/messages.  
  **Maps to**: FR-ESC-01/02/03, FR-REM-07 (snooze = +15)

#### Sprint 1 DoD
- Clickable prototype for P0 screens (SCR P0 list) + documented open questions list (max 10).

---

### Sprint 2 — Hi-fidelity UI + design system tokens

#### Epics / stories
**E3 — Design system**
- Define tokens:
  - color palette with contrast pairs verified (≥4.5:1 baseline)  
    **Maps to**: FR-L10N-07
  - type scale tied to SRS font sizes  
    **Maps to**: FR-L10N-04
  - component library: **`BigButton`** (48dp min), **`MedCard`** (Urdu large / English subtitle), **`StatusPill`**, **`DosageChip`**, chart components  
    **Maps to**: caregiver dashboard visuals

**E4 — Content & localization strategy**
- Translation workflow (Urdu translations locked, glossary for medical wording—avoid jargon).  
  **Maps to**: §8.5 friendly tone

**Micro-tasks**
- Add **RTL component checklist** (“don’t flip these icons incorrectly”, number formatting approach).  
  **Maps to**: §8.2 “eastern arabic numerals preference” decision recorded
- Map each screen widget to SRS acceptance checks (table).

#### Sprint 2 DoD
- UI kit stable enough that mobile dev can build without daily visual churn.
- “UX sign-off criteria” doc: what is allowed to change during build vs locked.

---

## Phase 2 — Technical foundation (Sprints 3–4)

**Goal**: Establish **secure auth**, **data model**, **API contracts**, **local DB**, and **push plumbing** so feature sprints don’t rewrite core.

### Sprint 3 — Contracts + security baseline

#### Epics / stories
**E5 — Data model + ERD + migrations approach**
- Tables: users, links, otp, medications, schedules, dose_logs, alert_events, devices (push tokens)
- Indexing plan for queries: today’s schedule, weekly adherence aggregates

**Micro-tasks**
- Write `DATA_MODEL.md` + ERD diagram (Mermaid).
- Define retention policy for logs (≥90 days) + archival approach.  
  **Maps to**: FR-LOG-03

**E6 — API contract (OpenAPI)**
- Endpoints from architecture doc, plus error model, pagination rules, idempotency keys for sync.

**Micro-tasks**
- Generate OpenAPI stub + example payloads for:
  - OTP create/verify
  - bulk dose log upsert
  - caregiver dashboard aggregates

**E7 — Threat model (minimum viable enterprise)**
- STRIDE hotspots: OTP brute force, caregiver accessing wrong patient data (IDOR), token theft, insecure storage, insecure push routing.

**Micro-tasks**
- Document mitigations mapped to SRS NFR-SEC-* acceptance tests.

#### Sprint 3 DoD
- Contracts reviewed by mobile + backend leads.
- Security checklist signed (even if informal for coursework—still disciplined).

---

### Sprint 4 — Mobile foundation + offline/local DB + scheduling skeleton

#### Epics / stories
**E8 — Local SQLite schema + repositories**
- Tables mirroring server entities (subset on device acceptable).
- “Outbox” table for offline sync queue.  
  **Maps to**: NFR-OFF-02/03

**Micro-tasks**
- Implement repositories:
  - medications repo
  - dose logs repo
  - outbox repo
- Create seed script for demo data.

**E9 — Notification engine skeleton**
- Alarm scheduling abstraction:
  - schedule / cancel / reschedule on medication edits
  - reschedule on reboot  
    **Maps to**: Android boot permission intent; SRS permissions §5.3

**Micro-tasks**
- Create emulator/device tests stubs for:
  - schedule alarm in T+2 minutes
  - reboot and verify reschedule (Android first if iOS build constraints)

**E10 — i18n/RTL infra in code**
- Language switching + persistence + RTL layout wrappers.  
  **Maps to**: FR-L10N-01/02
- Integrate Noto Nastaliq Urdu font assets.  
  **Maps to**: FR-L10N-03

#### Sprint 4 DoD
- A “shell app” demonstrates: language toggle + RTL + local DB writes + schedules a test alarm.

---

## Phase 3 — MVP feature build (vertical slices) (Sprints 5–10)

This is the longest phase; each sprint delivers **production-shaped slices** that demo end-to-end.

### Sprint 5 — Onboarding + roles + OTP linking (thin vertical slice)

**Sprint goal**: caregiver can link to patient account using OTP rules; tokens stored securely; session persists.  
**Maps to**: FR-AUTH-01..05, SCR-001..007, NFR-SEC-03/04/06 (+07 if implemented now)

#### Micro-tasks (mobile)
- Implement screens:
  - SCR-001 splash
  - SCR-002 language select (must be first substantive gate per SRS narrative)
  - SCR-003 role select
  - SCR-004 caregiver registration (minimum fields: name + phone/reg token strategy)
  - SCR-007 OTP entry UI + error states + lockout messaging

#### Micro-tasks (backend)
- OTP generation:
  - store hash, expiry 10 minutes, single use
  - rate limit failures (implement now if possible; otherwise stub + flag)
- Link creation + authorization middleware (“caregiver can only access linked patient”).

#### QA / verification
- Test matrix: OTP expired, OTP wrong 5 times, correct OTP happy path.
- Abuse cases: caregiver tries to fetch patient meds without link → must fail.

---

### Sprint 6 — Patient profile + medication CRUD (caregiver-driven)

**Sprint goal**: caregiver can CRUD meds with bilingual names, dose typing, frequencies, scheduled times; patient schedule orders correctly.  
**Maps to**: FR-MED-01/04/05, SCR-005/006/013/014, FR-AUTH-04

#### Micro-tasks
- Implement medication form validations (Urdu required? define rule; SRS implies bilingual names FR-MED-01)
- Photo capture placeholder (behind flag) if pursuing FR-MED-02 soon
- Conflict handling: updating schedule cancels conflicting alarms safely

#### Sync tasks
- Initial strategy: meds saved server-side authoritative; patient device pulls snapshot; patient offline can still operate if previously synced (align with NFR-OFF-05)

---

### Sprint 7 — Patient Home + statuses + ordering

**Sprint goal**: patient sees meds in chronological order + states (Taken ✓ / Upcoming ⏱ / Missed ✗).  
**Maps to**: FR-MED-03, FR-LOG-02, SCR-008

#### Micro-tasks
- Derived status engine:
  - define “scheduled dose instance” uniquely (medicineId + scheduledAt + day)
  - define transitions: upcoming → taken/snoozed/missed/escalated
- Accessibility: tap targets everywhere on home.

---

### Sprint 8 — Local reminders MVP (notifications + sounds + vibration + background reliability)

**Sprint goal**: reminders fire at correct time while app closed; selectable sound; vibration; actionable notification.  
**Maps to**: FR-REM-01..07, SCR-017, §5.3 permissions  
**Hard gate**: NFR-OFF-01

#### Micro-tasks
- Android:
  - request notification permission at need-time
  - exact alarm permission pathway + explanation UX
  - boot receiver re-registration
- iOS:
  - notification categories/actions: Taken / Snooze
  - plan critical alerts entitlement (document fallback strategy if unavailable)
- Sound selection persistence + preview UI

#### Verification (must be explicit)
- Alarm fires with:
  - data off / airplane mode intervals (should still locally fire)
  - after reboot (Android)
  - low power modes (best-effort; document failures)

---

### Sprint 9 — Snooze(+15), escalation(+15 louder), escalation events logging

**Sprint goal**: implement the timeline logic exactly as SRS; persist states; reduce duplicate alarms.  
**Maps to**: FR-REM-07, FR-ESC-01..05, FR-LOG-01

#### Micro-tasks
- Define escalation state machine (document in code + `docs/`):
  - T0 scheduled reminder
  - T+15 second reminder (louder channel / higher importance)
  - T+30 caregiver alert trigger (may be queued)
- Ensure “Taken cancels all pending escalations” (FR-ESC-04)
- Persist escalation events (FR-ESC-05 should-have: implement if time; else backlog with estimate)

---

### Sprint 10 — Dose logging + history + 90-day retention behavior

**Sprint goal**: durable logs, patient history view, retention rules.  
**Maps to**: FR-LOG-01/03, FR-LOG-04 (P1), SCR-011

#### Micro-tasks
- Local retention policy + sync to server
- Server retention + query endpoints
- History UI: 7-day should-have; still define architecture for 90-day server query

---

## Phase 4 — Caregiver dashboard + push alerts (Sprints 11–13)

**Sprint goal**: caregiver sees real-time today + weekly chart + receives push on misses; works gracefully offline/last-synced.  
**Maps to**: FR-CARE-01..04, FR-ESC-02/03, NFR-OFF-03/04 (+ FR-CARE-05 should-have)

### Sprint 11 — Dashboard “today” + aggregation service

#### Micro-tasks
- Backend aggregate queries (efficient) + caching optional
- Mobile dashboard UI: status list component (SCR-012)

### Sprint 12 — Weekly chart + adherence percent (optional should-have)

#### Micro-tasks
- Chart component + edge cases (partial days, timezone)
- Adherence definition documented (numerator/denominator) — avoid ambiguous metrics

### Sprint 13 — Push notification delivery hardening

#### Micro-tasks
- Device token lifecycle (refresh, logout)
- Retry queue for offline caregiver alert sending (NFR-OFF-03)
- Alert read/unread (SRS data model includes read state)

---

## Phase 5 — Hardening & non-functional completion (Sprints 14–16)

This phase is what makes the app “enterprise-ready” beyond “it works on my phone”.

### Sprint 14 — Security & privacy completion

**Maps to**: NFR-SEC-01..07, privacy policy linkage in Settings (NFR-SEC-05)

#### Micro-tasks
- Enforce TLS only; pinning decision (optional; document tradeoffs)
- DB encryption at rest plan (managed DB + column-level decisions)
- Authorization tests as automated suite (“cross-patient access must fail”)
- OTP rate limit + observability counters

---

### Sprint 15 — Offline sync correctness + conflict resolution proofs

#### Micro-tasks
- Property tests / integration tests for outbox replay
- Idempotency keys for log upserts
- “Last updated” UI on caregiver dashboard offline mode (NFR-OFF-04)

---

### Sprint 16 — Performance, battery, and alarm reliability marathon

#### Micro-tasks
- Stress test: 5 meds × 4 times/day schedules; ensure scheduler performance OK
- Battery impact notes; reduce wakeups; batch operations
- Crash analytics + breadcrumbs (privacy reviewed)

---

## Phase 6 — QA, UAT, release (Sprints 17–18)

### Sprint 17 — Full regression + SRS traceability audit

#### Micro-tasks
- Build **Requirements Traceability Matrix (RTM)**: FR/NFR/SCR → test case IDs → results
- Usability sessions targeting SUS (NFR-USE-01) — even if simplified for coursework

### Sprint 18 — Release candidate, store readiness, rollout

#### Micro-tasks
- Play/App store listings, permissions disclosures, screenshots in Urdu/English
- Staged rollout plan + hotfix branching strategy
- Post-release monitoring checklist (crash rate, failed push deliveries)

---

## Phase 7 — Continuous delivery / new features (post-MVP, ongoing)

Treat this as **infinite agile** with quarterly planning.

### How new features enter
- **Intake**: problem statement + UX impact + security/privacy delta
- **Architecture decision record (ADR)** if it changes data model or notification logic
- **Feature flag** + incremental rollout

### Near-term backlog candidates (explicitly NOT MVP per SRS)
- Doctor portal (future user)
- WhatsApp bot (future)
- Automatic pill identification (future)
- FR-MED-02 photo capture polish + storage governance
- FR-L10N-05 Urdu TTS polish (offline/online voices, quality testing)
- Multi-caregiver linking, caregiver teams, audit logs (common real-world expansion)

### Suggested cadence after MVP
- **2-week sprints** unchanged
- **Monthly** security dependency review + threat model delta
- **Quarterly** deeper usability retest + retention policy review

---

## Living artifacts you should maintain (lightweight governance)
- `docs/RTM.csv` (requirements → tests)
- `docs/ADR/` (architecture decisions)
- `docs/RUNBOOK.md` (how to diagnose alarm/push/sync failures)
- Release notes per sprint (even internal)

---

## Practical “first 3 sprints” recommendation (if you want a clean start immediately)
If you want the least risky sequencing:
1) **Sprint A**: UX P0 screens + notification permission UX copy + alarm test harness  
2) **Sprint B**: Local DB + schedule + reboot tests (Android-first)  
3) **Sprint C**: OTP linking + secure session + authorization middleware  

This aligns with mitigating the biggest program risks early: **HCI clarity** and **alarm reliability**.
