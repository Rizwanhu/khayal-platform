# Khayal - Simple Work Plan (3 Members)

## What is already done (Phase 1 done)

- UI screens are ready in `lib/screens/...`
- Roles are ready: Patient, Caregiver, Doctor
- Navigation is working
- Theme baseline is applied

Now only core logic + backend integration is left.

---

## Phase 2 (Current Work) - Do in this order

### Step A - Member 2 works first (Backend/Supabase) and pushes

Member 2 tasks:
- [x] Run database SQL from `DATABASE.md` in Supabase
- [x] Create/finalize RLS so:
  - patient sees own data only
  - caregiver sees linked patient data
  - doctor sees linked patient data as read-only
- [ ] Build and test queries/functions for:
  - medications CRUD
  - dose logs
  - caregiver dashboard summary
  - doctor patient list + history
- [ ] Add sample data (1 patient, 1 caregiver, 1 doctor, linked correctly)
- [ ] Push code + SQL notes

**Deliverable from Member 2:**  
“Backend ready for integration” + list of endpoints/queries + sample test users.

Status update:
- Database schema + policies are already applied in Supabase.
- Remaining Member 2 work is API/query layer + sample data + push notes.

---

### Step B - Member 3 works second (Integration + QA) and pushes

Member 3 tasks:
- [ ] Connect Flutter service layer to Member 2 backend
- [ ] Wire these flows end-to-end:
  - caregiver adds medication -> patient sees medication
  - patient marks dose -> caregiver dashboard updates
  - doctor opens patient list -> doctor opens patient history
- [ ] Add loading/error/empty states in connected screens
- [ ] Create simple checklist in `TESTING.md`
- [ ] Test on Chrome + Android
- [ ] Log bugs (P0/P1), fix what is in scope, then push

**Deliverable from Member 3:**  
“Integration complete” + test results + bug list (if any).

---

### Step C - Member 1 (You) final pass after both pushes

Your tasks after Member 2 and Member 3 push:
- [ ] Pull latest changes
- [ ] Resolve merge conflicts (if any)
- [ ] UI polish (spacing/text/colors)
- [ ] Verify role permissions from UI side
- [ ] Run final demo flow for all 3 roles

---

## Copy-paste assignment messages

### Message for Member 2
“Please take backend first. Run `DATABASE.md` SQL in Supabase, finalize RLS for patient/caregiver/doctor, build medication+dose+dashboard queries, seed sample linked users, then push and send me the endpoint/query contract.”

### Message for Member 3
“After Member 2 push, please do integration. Connect Flutter to backend, complete 3 key flows (caregiver->patient, patient->caregiver update, doctor read-only history), add testing checklist in `TESTING.md`, test on Chrome+Android, then push.”

---

## Daily update format (everyone)

- Done yesterday:
- Doing today:
- Blocker:

If blocker > 2 hours, report immediately.

