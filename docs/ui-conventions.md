# DriveVault — Mobile UI Conventions (read on demand)

Screen/widget-level conventions. **Not loaded every session** — read this when
building or editing a mobile form/screen. CLAUDE.md links here.

- UI design references live in `docs/design-references/` (`mockup-screens.html`,
  `DESIGN-LANGUAGE.md`, `ref-0N-*.png` screenshots).

## Forms & headers

- Mobile form screens use the shared `FormScreenAppBar`
  (`mobile/lib/shared/widgets/form_screen_app_bar.dart`): centered title, Cancel text
  button on the left, primary pill Save on the right (`horizontal: 12`, `vertical: 6`),
  and a smaller title font size (`16`). Used by fuel, vehicle, maintenance, document
  upload, and profile forms.
- Keep delete/destructive resource actions on detail/view screens, **not** on edit
  forms. Destructive profile actions (e.g. sign out) use red styling with a
  confirmation bottom sheet.

## Pickers

- Currency pickers use a bottom-sheet field (`BottomSheetPickerField`): rows show
  symbol + name, selection stores the ISO code, and the closed field shows the
  currency name only.

## Specific forms

- **Fuel log form:** place the Full tank toggle on the same row as the Liters field.
- **Add vehicle form:** odometer section above registration; distance-unit picker
  offers mile/km only and defaults to the user's preference; vehicle type defaults to
  Car; photo upload uses a light yellow background.

## Navigation

- `MainShell` stacks a floating tab bar above tab navigators; bottom sheets/modals
  that must cover the tab bar need `useRootNavigator: true`.
