# ScriptSeer — Claude Code / Coding-Agent Prompt Pack

## Product summary
ScriptSeer is an iPhone + iPad teleprompter app designed to be the most natural way to read on camera without looking like you're reading.

It supports:
- classic teleprompter mode
- in-app camera recording with script overlay near the lens
- speech-aware script progression with strict and smart modes
- mirroring/reversed text for physical teleprompter rigs
- rich script formatting
- AI-assisted script cleanup and teleprompter formatting

The product should feel like a blend of cinematic creator tool and luxury black/glass, with the usability confidence of iPhone Camera and the readability restraint of Notion.

## Build philosophy
- Swift + SwiftUI only unless there is a strong reason otherwise
- iPhone and iPad supported from the start
- opinionated, simple defaults
- local-first storage
- privacy-forward, on-device speech recognition where possible
- no account required for MVP
- architecture should be modular and easy to extend

## Recommended stack
- SwiftUI
- AVFoundation
- Speech framework
- SwiftData
- StoreKit 2
- Photos / PhotosUI
- UniformTypeIdentifiers + file importers

## Global non-functional requirements
- smooth prompt rendering during scroll and recording
- stable rotation behavior on iPhone and iPad
- robust autosave for scripts
- graceful degradation when speech recognition loses confidence
- accessible controls outside the prompt canvas
- clear state management for prompt sessions

---

# Master instruction for the coding agent

You are building ScriptSeer, a premium-feeling iOS teleprompter app for iPhone and iPad.

Your job is to implement the product in production-quality Swift using SwiftUI. Prefer simple, maintainable, modular architecture over cleverness. Use native Apple frameworks where possible. Keep the default UX opinionated and beginner-friendly, while allowing room for advanced controls.

Every sprint must:
1. ship working code
2. preserve previously built functionality
3. keep the app compiling cleanly
4. avoid placeholder architecture that will need total rewrites later
5. include concise inline comments only where useful

For each sprint below:
- implement the requested scope fully
- produce or update the necessary files
- explain any technical tradeoffs
- list any TODOs that are intentionally deferred
- ensure the acceptance criteria are satisfied

---

# Sprint 0 — Project foundation and design system

## Prompt to coding agent
Create the initial ScriptSeer iOS project in SwiftUI with support for iPhone and iPad.

Implement:
- app entry point
- root navigation structure
- tab bar with placeholders for Home, Scripts, Record, Practice, Settings
- shared design system
- theme tokens for luxury black/glass visual language
- reusable components for cards, glass panels, buttons, section headers, input rows, empty states
- app-wide typography, spacing, corner radius, shadow, and animation constants
- light haptics utility where appropriate
- app icon placeholder references and asset organization structure

Use a modular folder structure such as:
- App
- DesignSystem
- Features/Home
- Features/Scripts
- Features/Record
- Features/Practice
- Features/Settings
- Models
- Services
- Utilities

Create a clean, premium default appearance with:
- near-black backgrounds
- soft glass surfaces
- high-contrast text
- subtle accent color for active states
- refined recording red reserved for recording states only

Do not build business logic yet beyond enough scaffolding to navigate between tabs and render polished placeholder screens.

## Acceptance criteria
- App compiles and runs on iPhone and iPad
- Tab navigation works across all 5 tabs
- Shared design tokens exist in one place
- Reusable button/card/glass components exist and are used by placeholder screens
- UI already feels premium and visually coherent, not like default SwiftUI scaffolding
- Project structure is organized by feature and is ready for incremental development

---

# Sprint 1 — Script data model, local persistence, and script library

## Prompt to coding agent
Implement the local data model and script management system for ScriptSeer using SwiftData.

Create models for:
- Script
- ScriptVariant
- ScriptFolder (optional if lightweight)
- PromptSessionDraft or equivalent lightweight session state entity if needed

Each Script should support:
- id
- title
- raw text / rich text source representation
- createdAt
- updatedAt
- estimatedDuration
- tags or lightweight metadata if useful
- mirror preference defaults if needed later

Each ScriptVariant should support:
- parent script linkage
- title
- content
- source type (original, ai-cleanup, shortened, creator variant, etc.)
- createdAt
- updatedAt

Build the Scripts tab and core home content so users can:
- create a new script
- duplicate a script
- delete a script
- search scripts
- sort scripts by recent or title
- open a script detail/editor view
- see recent scripts on Home

Implement local autosave behavior and seed the app with a few preview/demo scripts for development.

## Acceptance criteria
- Scripts persist across relaunches
- User can create, edit title, duplicate, and delete scripts
- User can search scripts by title/content in a reasonable way
- Home shows recent scripts
- Script list feels polished on iPhone and iPad
- No account or network dependency exists for local script storage

---

# Sprint 2 — Script editor with teleprompter-focused formatting

## Prompt to coding agent
Build a polished script editor for ScriptSeer.

The editor should support:
- editing plain text smoothly
- optional rich formatting controls for bold, italic, underline, headings
- teleprompter-specific cues such as pause markers, emphasis markers, and section dividers
- estimated read time display
- autosave
- duplicate as variant
- clean formatting toolbar that does not overwhelm beginners

The editor UI should feel calm and premium, not like a generic note-taking app. Prioritize readability.

Support a simple underlying representation that is maintainable. If rich text becomes too complex for v1 architecture, use a structured lightweight markup approach internally, as long as the user-facing experience supports the required formatting.

Also add a “Make Promptable” entry point in the editor UI as a future AI action placeholder.

## Acceptance criteria
- User can write and edit scripts smoothly
- Formatting tools exist and persist after save/reopen
- Teleprompter cue markers can be inserted and rendered distinctly
- Estimated duration updates reasonably based on content length
- Variant duplication works from the editor
- Editor is usable on both iPhone and iPad without cramped layout

---

# Sprint 3 — File import pipeline

## Prompt to coding agent
Implement script import for ScriptSeer.

Support importing from Files for:
- TXT
- RTF
- PDF
- DOCX

The import flow should:
- allow selecting a file
- extract text as reliably as practical
- create a new Script from imported content
- preserve useful formatting where feasible
- fail gracefully with a friendly error if parsing is not possible

Add import entry points from:
- Home
- Scripts tab
- editor toolbar if appropriate

Where format preservation is difficult, prioritize clean readable text extraction over perfect fidelity.

## Acceptance criteria
- User can import TXT, RTF, PDF, and DOCX files from Files
- Imported text is saved as a new script and can be edited
- Failed imports show a non-technical error message
- Import is available from at least Home and Scripts
- App remains responsive during import

---

# Sprint 4 — Classic teleprompter mode

## Prompt to coding agent
Build the core classic teleprompter experience.

Users should be able to open any script and enter a full-screen prompt mode with:
- play/pause
- adjustable manual scroll speed
- adjustable text size
- adjustable line spacing
- adjustable horizontal margins
- high-contrast theme presets
- countdown delay before start
- portrait and landscape support
- mirrored/reversed text mode for physical teleprompter rigs
- one-line, two-line, chunk, and paragraph display modes

Implement a prompt rendering engine that feels smooth and stable. The UI should hide complexity by default but expose a “Tune” controls panel.

Also implement:
- jump to section/cue if available
- quick jump-back by sentence or paragraph
- visible session state controls without visual clutter

## Acceptance criteria
- User can start prompting within 2 taps from a script
- Scroll is smooth and visually stable
- Live adjustment of speed, size, spacing, and margins works during prompting
- Mirrored mode works correctly in both portrait and landscape
- One-line, two-line, chunk, and paragraph modes all render sensibly
- Jump-back works without resetting the full session

---

# Sprint 5 — In-app camera recording with script overlay

## Prompt to coding agent
Build ScriptSeer’s camera-overlay recording mode using AVFoundation.

The mode should support:
- front and rear camera
- live camera preview
- overlay text positioned near the lens area
- prompt controls while recording
- start countdown
- pause/resume recording if feasible in architecture; otherwise provide a clear staged approach
- save output to Photos and/or in-app recording list
- exposure/focus lock if practical
- framing guides
- orientation-safe behavior

The overlay must be highly legible over live video while still feeling elegant. Prioritize a natural eye-contact layout, not just text floating anywhere on screen.

Also add a basic recordings list or session results screen so users can review what they just captured.

## Acceptance criteria
- User can record video inside the app with prompt text over the preview
- Front and rear camera selection works
- Prompt overlay remains readable across typical backgrounds
- Recorded video saves successfully
- Basic review/list screen exists for recordings
- Camera mode works on both iPhone and iPad where hardware supports it

---

# Sprint 6 — Speech-aware prompting engine

## Prompt to coding agent
Implement ScriptSeer’s speech-aware prompting system using Apple’s Speech framework where possible.

Build a dedicated SpeechFollowEngine with two modes:
- Strict mode: advances based on close word-by-word matching
- Smart mode: advances based on phrase-level/fuzzy matching and tolerates filler words, pauses, minor paraphrases, and small skips

Requirements:
- on-device/privacy-forward where possible
- state machine for listening/following/low-confidence/manual assist
- confidence thresholding
- graceful fallback when recognition quality drops
- never jump wildly through the script on weak confidence
- support both classic prompt mode and camera-overlay mode

Also create a small developer diagnostics overlay or internal debug logging option to inspect recognition state during testing.

## Acceptance criteria
- Strict mode follows spoken words in a way that clearly advances the script
- Smart mode is more tolerant and feels meaningfully different from strict mode
- Low-confidence state is visible and does not produce erratic jumps
- Speech-follow can be started/stopped from the prompt UI
- Manual controls still work when speech-follow is active
- The engine is encapsulated cleanly enough to improve later without rewriting UI

---

# Sprint 7 — Focus Window, eye-contact optimization, and natural reading UX

## Prompt to coding agent
Implement ScriptSeer’s core differentiation features focused on natural eye contact.

Build:
- Focus Window mode that shows only the current sentence/phrase plus minimal context
- current phrase highlighting
- de-emphasized past/future lines
- adjustable vertical offset so text can sit near the lens
- short-line readability layout presets
- glance-minimizing presets for selfie, webinar, speech, and audition
- smarter line reflow/chunking heuristics for prompt readability

This sprint should make the app feel tangibly better than a generic teleprompter.

## Acceptance criteria
- Focus Window mode exists and is usable in both classic and camera-overlay mode where appropriate
- Current line/phrase is clearly emphasized
- User can place text nearer the lens area with a controlled offset
- Presets materially change layout behavior in a useful way
- Reading experience feels more natural and less scan-heavy than a standard scrolling wall of text

---

# Sprint 8 — Practice mode and stumble review

## Prompt to coding agent
Build a Practice mode for ScriptSeer.

Users should be able to rehearse without recording and get lightweight feedback such as:
- total time
- approximate pace
- stumble markers or difficult-line flags
- ability to review flagged lines
- retry from a flagged line or previous sentence

This should not feel like a judgmental coaching app. Keep the tone supportive and practical.

Use existing speech-follow infrastructure where helpful.

## Acceptance criteria
- Practice mode can be launched from a script
- User can rehearse without recording video
- Practice session returns at least basic timing and flagged-line feedback
- User can jump back into the script from a flagged line or nearby section
- Practice flow feels integrated with the rest of the app

---

# Sprint 9 — AI actions and script variants

## Prompt to coding agent
Implement the AI-assisted script workflow for ScriptSeer behind a service abstraction.

Build UI and architecture for these actions:
- Make Promptable
- Shorten
- Simplify
- Rewrite more conversationally
- Generate alternate take
- Split into readable chunks

Requirements:
- every AI action creates a new ScriptVariant by default rather than overwriting the original
- original content remains easy to return to
- AI action sheet feels clear and premium
- service layer should be easy to wire to a real provider later
- for now, if no API key/provider is configured, provide a mocked implementation path for development

Do not hard-code the app to a single AI vendor.

## Acceptance criteria
- User can trigger AI actions from a script/editor
- AI results save as separate variants
- User can browse/select variants for the same base script
- Original script is preserved
- Architecture supports swapping in a real backend/provider later

---

# Sprint 10 — Remote controls, keyboard shortcuts, and pro polish

## Prompt to coding agent
Add interaction polish and accessory support.

Implement:
- hardware keyboard shortcuts for play/pause, faster/slower, next/previous cue, jump-back
- basic controller support if practical
- better empty states
- loading states
- error toasts/banners
- settings screen for prompt defaults, speech-follow behavior, and camera defaults
- onboarding tips for first-time users
- basic StoreKit 2 paywall scaffolding, but do not aggressively gate the basic product

Also refine iPad layouts and orientation behavior.

## Acceptance criteria
- Keyboard shortcuts work in prompting contexts
- Settings allow changing important defaults
- Onboarding/tips exist for first-time users
- App feels polished and coherent across major flows
- Basic monetization scaffolding exists without harming core usability

---

# Sprint 11 — QA hardening and release candidate

## Prompt to coding agent
Turn ScriptSeer into a release-candidate quality app.

Focus on:
- bug fixes
- edge-case handling
- performance tuning
- iPad refinement
- stability during long prompt sessions
- stability during import and recording
- speech-follow fallback edge cases
- data migration safety for existing local scripts if needed
- accessibility pass for core controls
- final visual polish

Create a concise QA checklist and identify any remaining known issues explicitly.

## Acceptance criteria
- Core flows are stable: create/import script, edit, prompt, record, speech-follow, practice, review
- No major visual breakage across iPhone and iPad common sizes
- Recording, prompt, and speech states recover gracefully from common interruptions
- Known issues are documented clearly
- App is in shippable beta/release-candidate condition

---

# Optional stretch sprint — Floating overlay experiments and advanced platform constraints

## Prompt to coding agent
Investigate the most realistic implementation options for a floating overlay or adjacent workflow on iOS/iPadOS, given Apple platform limitations.

Do not promise unsupported Android-style system overlays if the platform does not allow them.

Instead, explore and prototype the best feasible options such as:
- iPad split view workflows
- secondary device controller mode concept
- picture-in-picture style assist patterns if any are valid
- alternate in-app UX that captures the spirit of overlay use cases

Produce a short engineering note explaining what is and is not realistically possible on Apple platforms.

## Acceptance criteria
- A documented technical conclusion exists
- Any prototype implemented is platform-compliant
- Product language can be updated accurately based on findings

---

# Shared design notes for all sprints
- Avoid gaudy neon or generic creator-app clutter
- Prefer black, graphite, glass, subtle glow
- Keep prompt text extremely readable
- Default screens should feel calm and luxurious
- Use motion sparingly and purposefully
- Advanced controls should be hidden until needed

# Shared product notes for all sprints
- ScriptSeer is for everyday confidence and creators, not only pro studios
- The main promise is natural reading on camera without looking like reading
- The app should feel trustworthy, private, and polished
- Basic utility should not be trapped behind an overly aggressive paywall

# Suggested folder structure
```text
ScriptSeer/
  App/
  DesignSystem/
  Models/
  Services/
    AI/
    Speech/
    Camera/
    Persistence/
  Features/
    Home/
    Scripts/
    Editor/
    Prompt/
    Record/
    Practice/
    Settings/
    Onboarding/
  Utilities/
  Resources/
```

# Suggested state machines
## Prompt session state
- idle
- countdown
- promptingManual
- promptingSpeechFollow
- lowConfidenceAssist
- paused
- recording
- completed
- failed

## Recording state
- idle
- preparing
- countdown
- recording
- paused
- finishing
- saved
- failed

## AI action state
- idle
- loading
- success
- failed

# Final instruction to coding agent
When working sprint by sprint, always preserve a clean architecture that supports:
- local-first script ownership
- camera overlay prompting
- speech-aware alignment
- AI-generated variants
- premium UI polish
- future pro expansion without rewriting the app foundation
