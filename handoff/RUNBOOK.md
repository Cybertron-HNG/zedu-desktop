# Runbook

## Setup

```bash
cp .env.example .env
flutter pub get
```

## Verify

```bash
flutter test test/widget/features/user_profile/presentation/views/roles_and_permissions_section_test.dart
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

## Deliver

```bash
git push -u fork fix/ziki-248-role-permissions-copy
gh pr create \
  --repo zeduchat/zedu-desktop \
  --base staging \
  --head AbdKabeer1:fix/ziki-248-role-permissions-copy
```
