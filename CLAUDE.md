# ScriptSeer

## What is this?
ScriptSeer is an iPhone + iPad teleprompter app built in Swift/SwiftUI. It helps people read on camera naturally without looking like they're reading.

## Tech stack
- Swift + SwiftUI (no UIKit unless absolutely necessary)
- AVFoundation (camera/recording)
- Speech framework (on-device speech recognition)
- SwiftData (local persistence)
- StoreKit 2 (monetization)
- Photos/PhotosUI (media export)
- UniformTypeIdentifiers (file import)

## Architecture
- Modular feature-based folder structure
- Local-first, no account required
- On-device speech recognition (privacy-forward)
- AI service abstraction layer (vendor-agnostic)

### Folder structure
```
ScriptSeer/
  App/                  # Entry point, root navigation, tab bar
  DesignSystem/         # Tokens, reusable components (cards, glass panels, buttons)
  Models/               # SwiftData models (Script, ScriptVariant, ScriptFolder)
  Services/
    AI/                 # AI action abstraction (vendor-agnostic)
    Speech/             # SpeechFollowEngine (strict + smart modes)
    Camera/             # AVFoundation capture pipeline
    Persistence/        # SwiftData container, autosave
  Features/
    Home/               # Dashboard, recent scripts
    Scripts/            # Script library, search, sort
    Editor/             # Script editor, formatting, cue markers
    Prompt/             # Classic teleprompter, focus window, display modes
    Record/             # Camera overlay recording, recordings list
    Practice/           # Rehearsal mode, stumble review
    Settings/           # Defaults, preferences, onboarding
    Onboarding/         # First-time tips
  Utilities/            # Haptics, helpers
  Resources/            # Assets, previews
```

### Key state machines
- **Prompt session**: idle -> countdown -> promptingManual/promptingSpeechFollow -> lowConfidenceAssist -> paused -> completed/failed
- **Recording**: idle -> preparing -> countdown -> recording -> paused -> finishing -> saved/failed
- **AI action**: idle -> loading -> success/failed

### Key models
- `Script` — id, title, raw text, createdAt, updatedAt, estimatedDuration, tags, mirror preference
- `ScriptVariant` — parent script linkage, title, content, source type (original, ai-cleanup, shortened, etc.), timestamps
- `ScriptFolder` — lightweight grouping (optional)

## Design language
- Luxury black/glass aesthetic — near-black backgrounds, soft glass surfaces, high-contrast text
- Subtle accent color for active states; recording red reserved only for recording states
- Calm, premium feel — no gaudy neon or generic creator-app clutter
- Motion used sparingly and purposefully
- Advanced controls hidden until needed
- Prompt text must be extremely readable at all times

## Git conventions
- Do NOT include "Co-Authored-By" lines in commit messages

## Code conventions
- Swift + SwiftUI only unless there is a strong reason otherwise
- Prefer simple, maintainable, modular architecture over cleverness
- Use native Apple frameworks where possible
- Opinionated, simple defaults
- Concise inline comments only where useful — don't over-document
- Every change must keep the app compiling cleanly
- Preserve previously built functionality when adding new features
- No placeholder architecture that will need total rewrites later

## Sprint roadmap
- **Sprint 0**: Project foundation, design system, tab navigation, reusable components
- **Sprint 1**: Script data model (SwiftData), script library CRUD, home screen
- **Sprint 2**: Script editor with teleprompter formatting, cue markers, autosave
- **Sprint 3**: File import pipeline (TXT, RTF, PDF, DOCX)
- **Sprint 4**: Classic teleprompter mode (scroll, mirror, display modes, tune controls)
- **Sprint 5**: Camera recording with script overlay (AVFoundation)
- **Sprint 6**: Speech-aware prompting (strict + smart modes via Speech framework)
- **Sprint 7**: Focus window, eye-contact optimization, natural reading UX
- **Sprint 8**: Practice mode, stumble review
- **Sprint 9**: AI actions and script variants (vendor-agnostic service layer)
- **Sprint 10**: Remote controls, keyboard shortcuts, settings, onboarding, StoreKit 2
- **Sprint 11**: QA hardening, release candidate
- **Stretch**: Floating overlay research, iPad split view, secondary device controller

## Product principles
- For everyday confidence and creators, not only pro studios
- Main promise: natural reading on camera without looking like reading
- Feels trustworthy, private, and polished
- Basic utility never trapped behind an aggressive paywall
- Usability confidence of iPhone Camera + readability restraint of Notion
