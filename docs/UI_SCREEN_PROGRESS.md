# Dashboard UI progress

## Baseline inspection (2026-10-12)

Scope: Dashboard only. No backend, Supabase, notifications, forecast calculations,
or other screens. This copy has a horizontal SingleChildScrollView/Row sensor
strip on mobile, not a PageView. Preserve that existing scrolling mechanism.

Original typography (logical pixels; normal/upright throughout):

| Role | Family / style | Size | Weight |
| --- | --- | --- | --- |
| Page heading | Manrope / pageHeading | 18 mobile, 24 desktop | 700 |
| Realtime and insight headings | Manrope / sectionTitle | 17 narrow, 19 wide | 700 |
| Forecast Overview heading | Manrope / sectionTitle | 20 | 700 |
| Sensor headings | Manrope / sectionTitle | 14 dense, 15 compact, 17 regular | 700 |
| Sensor values | Manrope / title | 28 dense, 25 compact, 30 regular | 700 |
| Insight trend / horizon values | Manrope / sectionTitle | 19 / 22 | 700 |
| Body / Outlook label | Work Sans / body, bodyBold | 14 | 400 / 600 |
| Metadata / badges / selectors | Work Sans / cardMeta | 12 | 400 / 700 / 700 |
| Sensor ranges | Work Sans / bodyBold | 12 compact, 13 otherwise | 600 |
| Sensor timestamps | Work Sans / cardMeta | 10 compact, 11 otherwise | 400 |
| Chart axes | Work Sans / cardMeta | 10 numeric/mobile time, 12 desktop time | 400 |
| Chart annotation | Work Sans / cardMeta | 9 mobile, 11 desktop, additionally FittedBox-shrunk | 400; values 700 |
| Insight explanation | Work Sans / cardMeta | 12, line height 1.35 | 400 |
| Insight threshold / crossing values | Work Sans / bodyBold | 12 | 600 |
| Details links | Theme TextButton / Work Sans labelLarge | theme default 14 | 500 |

Original layout: outer vertical scroll at all sizes; desktop 3:7 columns from
1150px; chart fixed at 230/350px; insight stacks below 820px of card content;
mobile sensors fixed at 190px wide with content-driven heights.

## Layout changes

- Extracted a presentation-only DashboardLayout and DashboardRealtimeSection so
  the actual layout can be tested with fixture data, without a controller or
  Supabase initialization. Existing Dashboard controller inputs remain intact.
- Header is measured first; desktop body uses the remaining viewport height.
  Preserved the 3:7 left realtime/right forecast layout and insight above overview.
  A 640px body minimum (adjusted for text scale) allows short windows to scroll.
  Above 120% text scaling, sections stack and scroll instead of compressing text.
- Desktop sensor cards share equal allocated heights. Narrow cards use the
  original horizontal SingleChildScrollView and Row, with equal intrinsic heights
  and viewport-responsive 240–300px widths. At 390px the active card is fully
  visible, with a small next-card hint. Tablet uses the same strip.
- Insight reserves the larger of its pH/EC bodies using IndexedStack. Its wide
  layout begins at 700px of inner card width. Full explanations wrap without
  ellipsis; narrow controls and links wrap.
- Forecast Overview fills its desktop allocation; stacked layouts get a height
  based on width and text scale, independent of selected series or interval.
  Chart expands into remaining space. Annotation and legend space is reserved
  across series selections; annotations sit above the plot instead of shrinking
  over it. Narrow controls wrap according to card width, not just screen width.
- Removed the duplicate right Value axis. Numeric axis labels use two decimals;
  exact six-decimal readings/tooltips and chart series are unchanged. Narrow time
  labels use two lines and fewer ticks at enlarged text scales. Tooltip bounds
  and plot clipping keep chart painting within its allocation.
- Gauge units sit below values. Gauge drawing and endpoint labels stay inside
  the allocated width; gauge ticks honor text scaling. Full timestamps wrap.

## Updated typography

All families, colors, normal/upright styles, and roles remain as recorded above.
No global text styles or theme files were changed. Changes were made after the
initial responsive layout implementation:

| Role | Updated style | Difference from baseline |
| --- | --- | --- |
| Forecast Overview heading | Manrope 17 narrow / 19 wide, 700 | Matches other section headings; previously 20 |
| Dense sensor value | Manrope 22, 700 | Previously 28; retains full precision and text scaling |
| Sensor range | Work Sans 12, 600, height 1.2 | Previously 13 outside compact mode |
| Sensor metadata | Work Sans 12, 400, height 1.2 | Explicit line spacing for compact desktop cards |
| Last updated label / timestamp | Work Sans 11, 400, height 1.2 | Label previously 12; mobile timestamp previously 10 |
| Chart numeric/time axes | Work Sans 11, 400 | Previously 10 numeric/mobile time and 12 desktop time |
| Current/forecast annotation | Work Sans 12, 400 | Previously 9/11 with additional FittedBox shrinking; now wrapping text |
| Offline sensor value | Manrope 22 dense / 25 compact, 700 | Previously inherited 32; fits the same sensor allocation |

Page heading, sensor headings, insight headings/values, badges, selectors,
details links, and insight explanation styles are unchanged. Gauge endpoint
formatting now uses whole numbers for the scale limits; sensor readings are
unchanged.

## Validation results

- `dart format`: completed on all seven changed/new Dart files.
- Targeted `flutter analyze --no-pub`: no errors or new warnings. Exit code 1
  reflects four existing unused private methods in dashboard_screen.dart:
  `_buildInsightContent`, `_insightColor`, `_combinedPredictionStatus`, and
  `_showAlertAdminDialog`. These pre-existing methods were left alone.
- `flutter test --no-pub test/dashboard_layout_test.dart
  test/forecast_cards_consistency_test.dart test/forecast_unavailable_test.dart`:
  **14 tests passed** (9 new layout tests and 5 existing regression tests).
- Fixture widget tests at 390×844, 768×1024, 1366×768, and 1440×900 check layout
  exceptions, equal sensor dimensions, pH/EC insight dimension stability, and all
  nine Both/pH/EC × 4h/8h/12h chart combinations. Desktop cases assert zero body
  scroll extent and the overview fits within viewport height.
- Narrow tests verify the final sensor card can be brought fully into view.
  Additional tests cover offline sensors/forecasts at 390 and 1366px, 200% text
  scaling at those widths, and a short 1366×500 viewport.
- Tests use fixture data and the real AppHeader with notification callbacks
  supplied to bypass its live bell service. No production app was launched,
  Supabase initialized, packages installed, or backend/configuration changed.
- Flutter/Dart were not on PATH; used the existing SDK recorded in
  android/local.properties. Flutter required permission to access its SDK cache.

## Remaining visual review and status

**Dashboard implementation complete; browser screenshot review pending.**
Widget geometry/overflow checks passed, but they are not screenshots with the
actual browser font metrics or production data. Review light/dark browser
screenshots at the four target sizes for gauge/value spacing, chart tick
legibility, tooltip positioning, and the existing shared header's title/profile
truncation with long names or enlarged text. Nonlinear browser text scaling and
unusually long metadata remain unverified. Production-connected visual testing
was intentionally not launched. No other screens were changed.

## Focused gauge correction and read-only investigation (2026-10-12)

### Gauge correction

The responsive pass reduced the dense gauge area from 140px to 100px and the
radius multiplier from 0.50 to 0.36 of height. That combination noticeably shrank
the semicircles. This correction removes that fixed dense height: the gauge
uses the remaining height inside its existing equal-sized card. The arc radius
now fills the available drawing region, with a thicker 10–18px track and a
proportional needle hub.

Arc/ticks, reading, and unit now occupy separate vertical regions rather than
sharing a Stack. Tick placement reserves the full label height plus clearance
below the arc stroke. Endpoint labels remain within the canvas, and EC's full
reading and mS/cm unit have separate lines. pH reserves the same unit-line space
so all three dials align. Dense card padding changes from 10px to 8px; heading
and badge line height is 1.2. Compact gauge height changes from 140px to 190px
(scaled with text size). Tick text changes from Work Sans 10px to 11px with 1.2
line height; reading sizes remain 22px dense / 25px compact with explicit 1.1
line height. Font families, thresholds, scales, normalization, needle angles,
sensor values, and unit conversion calculations are unchanged.

The desktop columns, short-window scroll fallback, equal sensor card sizing,
mobile horizontal scrolling mechanism, and all forecast widgets are unchanged
in this correction. No carousel replacement was made.

Exact maintained files changed in this correction:

- `lib/widgets/dashboard_parameter_gauge.dart`
- `test/dashboard_layout_test.dart`
- `docs/UI_SCREEN_PROGRESS.md`

### Validation of the correction

- `dart format` completed for both changed Dart files.
- Targeted `flutter analyze --no-pub lib/widgets/dashboard_parameter_gauge.dart
  test/dashboard_layout_test.dart`: **No issues found**.
- Dashboard layout, forecast card consistency, and forecast unavailable tests:
  **14 passed**. Requested 390px, 768px, 1366×768, and 1440×900 cases remain
  covered, along with offline states, 200% text scaling, and 1366×500.
- Added paint-level checks for semicircle diameter (at least 95px desktop and
  210px narrow), stroke thickness, and horizontal paint bounds. Rectangle checks
  ensure the dial ends above the reading and the reading ends above the unit.
  Existing equal-card, zero-desktop-scroll, and forecast-mode size assertions
  continue to pass.
- An exploratory fixture-only raster capture produced images at 1366×768 and
  390×844. The shapes and spacing were inspected, but the temporary capture tests
  failed when pending Google Fonts requests ran in the mocked test environment.
  The images used fallback test glyphs, so this is **not** a successful browser
  typography check. The temporary capture harness/images were removed. No fonts
  or packages were installed and no connected application was launched.

### Forecast discrepancy: confirmed from local files

1. `DashboardController._refreshPredictiveData` calls
   `ForecastingService.getSharedForecastChartData` separately for pH and EC with
   `selectedHours: 12`. The service makes an HTTP GET to the compile-time
   `FORECAST_API_URL`, with `parameter`, `ph`, `ec`, `temp`, and `horizon` query
   parameters. The default is `http://127.0.0.1:8000/api/predict/forecast`.
2. `.vscode/launch.json` supplies `--dart-define-from-file=supabase.json`.
   That local JSON has no `FORECAST_API_URL`, so this recorded launch setup uses
   the localhost default unless additional build arguments override it. No
   existing compiled web bundle or Render deployment definition was found in
   the inspected project. The running Render endpoint/build was not observed.
3. The Supabase URL hosts in local `supabase.json` and `backend/.env` match.
   This verifies the files, not running-process overrides or Render settings.
   No credentials are included in this report.
4. Localhost and deployed-web error handling differ. For ordinary request
   failures/non-success responses, localhost can return synthetic forecast
   points at current reading +0.1, +0.2, and +0.3. Deployed web instead throws a
   forecast endpoint error. The specifically handled baseline/unconfigured
   errors still throw. The local fallback prediction constructors do not set
   `isFallback: true`, so those points can be displayed as predictions. This is
   existing service behavior, inspected only; it was not changed or invoked.
5. The FastAPI handler loads `ph_forecaster.keras`, `ec_forecaster.keras`, three
   scaler artifacts, and `model_config.json`. `FORECAST_MODEL_VERSION` defaults
   to `delta-lstm-v1`; the local `.env` has no override. That label is not an
   artifact checksum and does not establish that Render has identical files.
6. The backend fetches its own latest `sensor_history` baseline and, when
   available, substitutes those values for the query values. Inputs also include
   a 96-step history sequence and time-of-day features. The sequence is anchored
   to backend request time, not strictly to the sensor baseline timestamp.
7. The client keeps up to 32 in-memory forecast snapshots, keyed by user,
   baseline timestamp, parameter, horizon, and current values. The controller
   also skips regeneration for the same claimed baseline timestamp. The backend
   maintains a separate process-local response cache (default 48 entries), keyed
   by baseline ID, parameter, horizon, and model-version label. These caches are
   not shared across localhost and Render processes and have no time-based TTL.
8. The inspected forecast endpoint does not read previously saved
   `forecast_predictions` as its response cache. It generates or returns an
   in-memory response and may upsert prediction records on a cache miss. Therefore
   **even calling this GET endpoint could write to the database**; no endpoint
   calls or application launches were performed for this investigation.
9. The Dashboard consumes `predictions[].value`, rounded to two decimals by this
   backend, rather than its separate three-decimal `val_4h/8h/12h` fields or the
   six-decimal persisted records. Dashboard display formatting retains six
   decimal places. The UI's Generated timestamp is set by the controller when
   it receives data; it is not proof of the backend baseline or model version.

### Forecast discrepancy: possible explanations, not confirmed runtime causes

- Local request failure triggering the synthetic fallback, while Render returns
  model output. Values exactly +0.1/+0.2/+0.3 are a useful diagnostic clue.
- Different build-time forecast URLs, backend deployments, model/scaler files,
  model configuration, or runtime environment overrides.
- Different baseline IDs/history or different server-time features despite
  equal displayed current readings; equal readings alone do not identify an
  identical model input sequence.
- Separate process caches retaining outputs generated at different times for
  the same baseline. Reusing a version label does not prove model equality.
- Comparing different horizons, different frontend deployments, or fields with
  different rounding. No current browser response was captured to distinguish
  these possibilities.

Existing browser Network captures (without sending new requests) could compare
request URLs, query parameters, HTTP status, response `model_version`,
`baseline_history_id`, `baseline_recorded_at`, and `predictions`. Render's deployed
commit/artifact hashes and build-time defines would be needed to establish
deployment equality. The discrepancy's actual runtime cause remains unproven.

### Change provenance and remaining checks

The prior Dashboard UI edits in this conversation refactored presentation and
reserved both pH/EC bodies; they did not change endpoint selection, model inputs,
forecast point filtering, nearest-horizon selection, or prediction values.
Chart tick formatting and annotation placement did change presentation. This
gauge correction makes no edits to forecast widgets or forecast logic.

`git status` reports that this fresh-copy directory is not a Git repository.
Consequently there is **no Git diff available** to independently establish its
history or compare it with the Render deployment. Before/after SHA-256 checks
for the inspected backend artifacts/configuration, Supabase SQL, and frontend
controller/service files establish that those files were not changed during
this correction. No backend, production configuration, API endpoint, model,
environment variable, or database change was made.

**Status: gauge correction implemented and targeted validation passed; browser
visual sign-off pending.** Check actual Manrope/Work Sans rendering in light/dark
mode at the target sizes, especially EC tick/readout/unit spacing, mobile card
visibility while dragging, and browser zoom/nonlinear text scaling. The existing
shared header's truncation remains outside this gauge correction.
