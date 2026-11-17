# Design and review

An expedition desk, not a dense admin dashboard. First run offers one obvious primary action: create a world.
Warm graphite #111716, panel #1B2421, ink #EEF5EE, moss #83C76D, amber #E3B46C.
Semantic Material color scheme supports dark and light modes. Inter for UI, Outfit for headings, both bundled
under OFL so startup works offline. 4/8 spacing grid, 8px inputs, 12px panels, 16px hero.

Original forest artwork is bundled at `assets/images/expedition.png`. Generated with the built-in image generation tool.
Final prompt: "Panoramic original twilight evergreen expedition campsite, warm amber campfire and tiny canvas tent
on the right, layered blue-green pine forest, distant mountains, crescent moon, paper texture and editorial woodcut
shapes. Dark quiet left half for text overlay. Palette #111716, #83C76D, #E3B46C. No text, logos, characters or Klei art."
This is an original illustration, not extracted game art.

Phosphor Flutter 2.1 provides all icon fonts/codepoints. Flutter 3.47 makes IconData final, so `core/icons.dart` is a
small MIT-compatible const IconData adapter for the used glyphs; upstream's old IconData subclass is not imported.
No individual SVGs or hand-redrawn action icons. window_manager 0.5.1 is pinned: 0.7 requires Flutter 3.50/Dart 3.14.
Fonts use Flutter's local font loader, avoiding network-bound google_fonts runtime fetches.

Sidebar expands at 1140px; below it becomes an icon rail with tooltips. Wizard steps collapse to a compact progress
header below 1000px content width. Pages scroll rather than clipping text. Buttons have ≥48px hit areas.
Status includes a written state and icon. Password/token inputs are masked. Errors retain entered values.
No unnecessary animations; platform reduced-motion settings are respected by Flutter's Material controls.

Review checklist: first-run purpose/next action, existing profile behavior, wizard back/next/validation, no fake live
statistics, visible focus, 900/1050/1440 widths, enlarged text, RU and EN, light/dark, offline startup, scroll access.
Automated widget checks exercise the same desktop layout; screenshots and native smoke checks are recorded in testing.md.
