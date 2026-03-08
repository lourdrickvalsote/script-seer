# ScriptSeer Design System

## Color Palette

The entire app uses exactly 5 brand colors. All semantic tokens are derived from these.

| Swatch | Name | Hex | RGB |
|--------|------|-----|-----|
| Dark Forest | `darkForest` | `#0c120c` | `(12, 18, 12)` |
| Crimson | `crimson` | `#c20114` | `(194, 1, 20)` |
| Slate | `slate` | `#6d7275` | `(109, 114, 117)` |
| Silver Sage | `silverSage` | `#c7d6d5` | `(199, 214, 213)` |
| Lavender Mist | `lavenderMist` | `#ecebf3` | `(236, 235, 243)` |

---

## Semantic Color Tokens (Light / Dark)

### Backgrounds

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| `background` | `lavenderMist` | `darkForest` |
| `surface` | `white` | `darkForest` lightened 4% |
| `surfaceElevated` | `white` | `darkForest` lightened 8% |
| `surfaceGlass` | `slate` @ 8% opacity | `silverSage` @ 6% opacity |

### Text

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| `textPrimary` | `darkForest` | `lavenderMist` |
| `textSecondary` | `slate` | `silverSage` |
| `textTertiary` | `slate` @ 60% | `slate` |

### Accent & Interactive

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| `accent` | `crimson` | `crimson` lightened for contrast |
| `accentSubtle` | `crimson` @ 12% | `crimson` @ 15% |

### Recording State

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| `recordingRed` | `crimson` | `crimson` |
| `recordingRedSubtle` | `crimson` @ 12% | `crimson` @ 15% |

### Structural

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| `divider` | `slate` @ 15% | `silverSage` @ 8% |
| `shadow` | `darkForest` @ 20% | `darkForest` @ 40% |

---

## Teleprompter Themes

Teleprompter themes are separate from the app theme and always use explicit colors for readability:

| Theme | Text Color | Background |
|-------|-----------|------------|
| Light on Dark | `lavenderMist` | `darkForest` |
| Dark on Light | `darkForest` | `lavenderMist` |
| Green on Black | `#4dff4d` (green) | `black` |
| Yellow on Dark | `#fff299` (gold) | `darkForest` |

---

## Usage Rules

1. **All colors flow through `SSColors`** — never use raw Color() in views
2. **Accent = Crimson** — used for primary buttons, links, active states, tab tint
3. **Recording red = Crimson** — recording states share the brand red
4. **Materials** — `.ultraThinMaterial` is acceptable for camera/overlay controls
5. **Hardcoded white/black** — only in camera overlay views where transparency over live preview requires it
6. **Opacity modifiers** — use `textSecondary`/`textTertiary` tokens instead of `.opacity()` on text colors where possible
