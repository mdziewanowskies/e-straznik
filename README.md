# e-Strażnik — aplikacja mobilna (Flutter)

Natywna aplikacja mobilna **e-Strażnik** — kompanion **read-only** do web SaaS
monitorującego liczniki energii z Tauron eLicznik dla firm.

Aplikacja **czyta dane** z tego samego Supabase, który obsługuje wersję webową.
Synchronizacja z Tauron eLicznik odbywa się wyłącznie po stronie web (cron 1×
na dobę o 07:00). Aplikacja **nie loguje się** do Tauron i **nie pisze** do
tabel z odczytami.

## Stack

- Flutter 3.x (Dart 3, null-safe, Material 3)
- Supabase (`supabase_flutter`)
- Riverpod 2 (`flutter_riverpod`)
- go_router (z guardem auth)
- fl_chart (wykresy)
- Firebase Cloud Messaging + `flutter_local_notifications` (push)
- `google_fonts` (Space Grotesk + Inter)
- `intl` (`pl_PL`)

## Schema czytane przez apkę

`profiles`, `organizations`, `meter_points`, `tauron_accounts`,
`monthly_summary`, `power_15min_readings`, `power_exceedances`, `readings`,
`alerts`. Wszystko chronione przez RLS — aplikacja używa klucza
**anon (publishable)** i widzi tylko dane organizacji zalogowanego usera.

Jedyne dozwolone zapisy w apce:

- `device_tokens` — upsert tokenu FCM po zalogowaniu (tabelę tworzy migracja
  po stronie web, patrz prompt).
- `alerts.acknowledged_at` — oznaczenie alertu jako przeczytany przy otwarciu.

## Ekrany

1. **Splash + Login** — logowanie email/hasło. Brak rejestracji
   ("Konto tworzysz w panelu webowym e-strażnika").
2. **Dashboard** — lista PPE (status, KPI MTD, tg φ, przekroczenia), banner z
   `last_sync_at` z `tauron_accounts`.
3. **Szczegóły PPE** — taby: *Przegląd*, *Moc 15-min*, *Energia bierna*,
   *Odczyty*.
4. **Alerty** — lista z filtrami (severity, typ), oznaczanie jako przeczytane,
   deep link `estraznik://alerts/<id>` z pushy.
5. **Ustawienia** — profil (read-only), preferencje powiadomień (read-only),
   wylogowanie.

## Konfiguracja przed pierwszym uruchomieniem

### 1. Dependencies

```bash
flutter pub get
```

### 2. Maskotka

Wrzuć plik PNG maskotki jako `assets/images/mascot.png`. Bez tego pliku apka
będzie pokazywała fallbackową ikonę z gradientem (nie powoduje błędu).

### 2.1 Natywny splash screen

Splash (granat + maskotka) generuje `flutter_native_splash` z konfiguracji
w `pubspec.yaml`. Po każdej zmianie maskotki lub konfiguracji uruchom:

```bash
dart run flutter_native_splash:create
```

To wygeneruje:

- `android/app/src/main/res/drawable*/launch_background.xml` + ikony
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/*`
- zmieni `ios/Runner/Info.plist` i `Base.lproj/LaunchScreen.storyboard`

Splash trzymany jest aż do zakończenia `Supabase.initialize` (w `main.dart`
przez `FlutterNativeSplash.preserve` + `remove`), więc nie ma białego
mignięcia między natywnym splashem a Flutterem.

Cofnięcie (jeśli chcesz wrócić do domyślnego):

```bash
dart run flutter_native_splash:remove
```

### 3. Firebase (push notifications)

Aplikacja używa Firebase Cloud Messaging. Bez plików konfiguracyjnych apka
**uruchomi się** (`Firebase init skipped` w logach), ale push nie zadziała.

- **Android** — `android/app/google-services.json`
- **iOS** — `ios/Runner/GoogleService-Info.plist`

Pliki pobierz z konsoli Firebase z projektu `e-Strażnik` po dodaniu aplikacji
o ID:

- Android: `com.estraznik.app`
- iOS: `com.estraznik.app`

Po stronie backendu webowego trzeba mieć `FCM_SERVER_KEY` w secrets Lovable
Cloud i wysyłać push po INSERT do `alerts` jeśli
`notification_prefs.push === true`.

### 4. Deep links

Już skonfigurowane w `AndroidManifest.xml` i `ios/Runner/Info.plist`:

- `estraznik://alerts/<id>` — deep link z pushy do konkretnego alertu

### 5. Klucze Supabase

Domyślnie wpisane w `lib/config/supabase_config.dart` (URL + anon key). Klucz
anon **może** być w binarce — RLS chroni dane.

## Uruchamianie

```bash
flutter run                  # debug na aktywnym urządzeniu
flutter run -d "iPhone 15"   # konkretny symulator
flutter run --release        # release na podpiętym urządzeniu
```

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (wymaga macOS + Xcode + ustawione signing)
flutter build ipa --release
```

## Testy

```bash
flutter test                                  # wszystkie
flutter test test/widget_test.dart            # smoke logowania
flutter test test/dashboard_golden_test.dart  # golden test karty PPE
flutter test --update-goldens                 # regeneracja goldena
```

## Struktura

```
lib/
├── config/                  # Supabase URL + anon key
├── data/
│   ├── models/              # Profile, MeterPoint, MonthlySummary, Alert, …
│   └── repositories/        # AuthRepository, MeterPointsRepository, …
├── providers/               # Riverpod providers (auth, dashboard, alerty, …)
├── router/                  # go_router z guardem auth + redirect logic
├── screens/                 # 5 głównych ekranów
├── services/                # PushNotificationService, error_messages.dart
├── theme/                   # AppColors, AppTheme (Material 3, Space Grotesk + Inter)
├── utils/                   # Fmt (pl_PL: kWh, kvarh, kW, tg φ, daty)
├── widgets/                 # Mascot, MeterPointCard, KpiTile, StatusBadge, …
└── main.dart                # entrypoint, init Firebase + Supabase + intl
```

## Co po stronie web (TODO osobnym ticketem)

1. **Migracja** — tabela `device_tokens` z RLS:
   ```sql
   create table public.device_tokens (
     id uuid primary key default gen_random_uuid(),
     user_id uuid not null references auth.users(id) on delete cascade,
     token text not null unique,
     platform text not null check (platform in ('ios','android')),
     created_at timestamptz not null default now(),
     last_seen_at timestamptz not null default now()
   );
   alter table public.device_tokens enable row level security;
   create policy "own tokens" on public.device_tokens
     for all using (user_id = auth.uid()) with check (user_id = auth.uid());
   ```
2. **Trigger / cron** wysyłający FCM po INSERT do `alerts`, gdy
   `profiles.notification_prefs.push === true`.
3. `FCM_SERVER_KEY` w secrets Lovable Cloud.
