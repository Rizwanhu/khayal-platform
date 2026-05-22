# Pull Request Checklist

## Security / privacy
- [ ] I did **not** commit secrets (`.env`, API keys, passwords). If I did, I rotated them immediately.
- [ ] Supabase `service_role` key is **not** used in the mobile app.
- [ ] Patient/caregiver data access is protected (RLS / authz checks) for any new tables/queries.

## Quality
- [ ] I ran `dart format` / formatting is clean.
- [ ] I ran `flutter analyze` and fixed new issues.
- [ ] I ran `flutter test` (or explained why not).

## UX / device verification
- [ ] Tested on a **real device** if this touches reminders/notifications/permissions.
- [ ] Urdu/RTL still looks correct if UI changed.

## Docs
- [ ] I updated docs if architecture/database/testing/security changed.

