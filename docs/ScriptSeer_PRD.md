# ScriptSeer PRD — iOS Teleprompter App

## Market Context

Based on current App Store leaders, the market already has strong coverage for classic scrolling, mirroring for physical rigs, in-app recording, remote control, and some version of voice-following.

- **Teleprompter Pro** emphasizes mirroring, remotes, multi-device control, captions, and recording.
- **Teleprompter.com** pushes recording, live streaming, AI rephrasing, and subtitle generation.
- **PromptSmart** differentiates around speech-following.
- **Teleprompter for Video** is positioned around reading while recording.

The opportunity is not to simply “add a teleprompter,” but to **make the most natural, camera-first, trustworthy teleprompter**.

The most important product gap is **reliability and naturalness in speech-aware prompting**. Existing apps already market voice-following heavily, but user reviews still complain about scroll failures, stopped listening, orientation issues, reload friction, and subscription frustration. That creates a real opening: **better eye-contact UX, more reliable speech-aware pacing, and a more tasteful business model**.

---

## Working Title

**ScriptSeer**

Backup directions:

- GlassCue
- LensLine
- TruePrompt
- Closer

---

## Product Vision

Build the most natural way to read on camera without looking like you’re reading.

This app should feel equally useful for:

- creators recording short-form video
- speakers practicing or delivering talks
- actors filming self-tapes
- clergy giving sermons
- professionals recording updates
- educators and livestream hosts

---

## Positioning

Most teleprompter apps feel like utilities. This should feel like a **confidence tool**.

### Positioning Statement

A beautiful teleprompter and camera-overlay app that helps everyday people and creators speak naturally, maintain eye contact, and get better takes faster.

---

## Product Principles

### Natural over flashy
Every feature should reduce the feeling of “I’m obviously reading.”

### Beginner-friendly by default
Opinionated defaults, low setup friction, clean UI.

### Pro-capable under the hood
Mirroring, remotes, advanced formatting, rig support.

### Reliable enough for real takes
Speech-aware prompting must fail gracefully.

### Private where possible
Speech tracking should work on-device first.

---

## 1. Goals

### Primary Goals

- Help users read naturally while maintaining near-camera eye contact.
- Support both traditional teleprompter mode and camera-overlay recording mode.
- Offer best-in-class speech-aware prompting.
- Make the app feel premium and beautiful without becoming hard to use.
- Serve both iPhone and iPad well from v1.

### Success Criteria

- Users can create or import a script and start prompting in under 60 seconds.
- Users can successfully complete a recording session without learning advanced settings.
- Speech-aware prompting feels helpful, not unpredictable.
- Overlay mode materially improves on-camera delivery.
- App Store feedback mentions polish, ease, and natural eye contact.

---

## 2. Target Users

### Primary User Segments

#### 1. Everyday creators
TikTok, Reels, YouTube Shorts, talking-head content, ads, UGC.

#### 2. Professional communicators
Work presentations, async updates, webinars, course content, meetings.

#### 3. Performance and speaking users
Actors, audition self-tapes, clergy, educators, public speakers.

### Core Jobs to Be Done

- “Help me record without memorizing every line.”
- “Help me look at the camera while reading.”
- “Help the script move at my pace.”
- “Help me recover quickly when I mess up.”
- “Help me get a usable take fast.”

---

## 3. Competitive Insight

### What Incumbents Already Do Well

Current leaders already cover:

- script import
- font and speed controls
- mirroring
- remote control
- in-app recording
- captions and subtitles
- some speech-following
- live streaming in some cases

### Where ScriptSeer Can Win

#### A. Better speech-aware prompting
PromptSmart is the clearest speech-following incumbent, but review evidence across the category shows reliability matters more than just having the feature.

#### B. Better “reading without looking like reading”
PromptSmart explicitly mentions narrowing margins to reduce eye tracking, and some users praise when teleprompter text sits close enough to the lens to appear natural. That means the real battleground is not just scrolling text, but **eye-motion design**.

#### C. Better pricing trust
There are clear complaints in the category around aggressive subscriptions, billing surprise, and weak value perception. A friendlier pricing model is a product advantage, not just a revenue choice.

---

## 4. Product Scope

### Platforms

- **iPhone:** fully supported at launch
- **iPad:** fully supported at launch

### Orientation Support

- portrait
- landscape
- locked orientation per project or session

### Future Platform Extensions

- Mac companion or desktop script editor
- Apple Watch remote
- multi-device controller mode

### Core Modes

#### 1. Classic Teleprompter Mode
A full-screen prompting experience for practice, speeches, rigs, and mirror-glass setups.

#### 2. Camera Overlay Recording Mode
Record directly in-app with script positioned close to the lens.

#### 3. Floating Overlay Mode
Where technically feasible on iPad and iPhone, allow script overlay over supported use cases. If full system-wide overlay is restricted by iOS, support the closest possible alternative:

- picture-in-picture style helper where allowed
- side-by-side workflow on iPad
- external-display or controller modes
- “import into app, record here” as the primary fallback

> **Important note for engineering:** iOS does not allow arbitrary Android-style always-on-top overlays across other apps in the same way. Any floating overlay promise should be scoped carefully around what Apple actually permits. This needs product copy that is precise and not misleading.

---

## 5. MVP Feature Set

### 5.1 Script Creation and Management

- Create script in-app
- Paste script from clipboard
- Import from:
  - TXT
  - RTF
  - PDF
  - DOCX
- Folder and project organization
- Recents
- Duplicate script
- Version history for script revisions
- Autosave
- Search scripts
- Offline local storage by default
- Optional cloud sync later

### 5.2 Rich Script Formatting

- Bold
- Italic
- Underline
- Headings
- Paragraph spacing
- Beat and pause markers
- Emphasis highlighting
- Speaker labels
- Section dividers
- Cue points and bookmarks
- Inline comments or notes hidden during performance
- Estimated duration

### 5.3 Prompt Controls

- Manual scroll speed
- Timed scroll mode
- Start delay or countdown
- Tap to play or pause
- Scrub or jump to section
- Swipe back one sentence or one paragraph
- Adjustable margins
- Text size
- Line spacing
- Contrast themes
- Mirrored text or horizontal reversal
- Vertical flip for rig workflows if useful
- One-line mode
- Two-line mode
- Chunk mode
- Paragraph mode

### 5.4 Speech-Aware Prompting

Two modes:

#### Strict mode
- Word-by-word alignment
- Best for rehearsed exact scripts

#### Smart mode
- Phrase-level matching
- Tolerates:
  - filler words
  - small paraphrases
  - skipped phrases
  - pauses
  - ad-libs
  - re-entry after going off-script

#### Fallback behavior
If confidence drops below threshold:

- pause auto-follow
- show subtle “manual assist” state
- allow user to nudge forward or back
- never wildly jump unless confidence is very high

#### UX goals
- Start and stop with natural pacing
- No sudden speed spikes
- Smooth visual catch-up
- Transparent state indicator:
  - Listening
  - Following
  - Low confidence
  - Manual mode

### 5.5 Camera Recording

- Front and rear camera support
- 1080p and 4K options where available
- Frame rate options later
- Pause and resume recording
- Multiple takes per script
- Retake from last sentence
- Take naming
- Save to library
- Export video
- Optional clean feed and prompted feed metadata
- Audio input selection if feasible
- Bluetooth mic support
- Exposure and focus lock
- Safe area guides
- Center framing guides

### 5.6 Eye-Contact Optimization

This is the real wedge.

#### Features
- Lens-near text anchoring
- Adjustable vertical prompt offset
- Center-focus reading zone
- Short line wrapping
- Current phrase highlight
- De-emphasized past and future lines
- Focus Window mode that only shows the current sentence or phrase
- Glance-minimizing layout presets:
  - selfie
  - webinar
  - speech
  - audition

### 5.7 Remote and Accessory Support

- Bluetooth keyboard shortcuts
- Game controller support
- Simple remote actions:
  - play or pause
  - faster or slower
  - next or previous cue
- Apple Watch support later
- Secondary-device controller later
- External display support later

### 5.8 Teleprompter Rig Support

- Mirror or reverse text
- External display output
- Large text optimization for iPad
- Landscape-first rig mode
- Optional black background high-contrast mode

---

## 6. Differentiation Features

These are the features most likely to make the app genuinely stand out.

### 6.1 Focus Window Mode
Only the current thought is shown near the lens, with surrounding text minimized.

**Goal:** reduce visible eye scanning.

### 6.2 Confidence Scroll
Auto-scroll speed adapts to speaking pace, pauses, and confidence level.

### 6.3 Smart Jump Back
One tap jumps back to the previous sentence, cue, or thought block instead of forcing a full restart.

### 6.4 Practice Mode
- Rehearse without recording
- Detect stumbles
- Track pacing
- Mark difficult lines
- Show estimated delivery time

### 6.5 Energy Markup
Users tag lines with:

- emphasize
- smile
- slow down
- pause
- punchline
- sincerity

Then those cues appear elegantly during prompting.

### 6.6 Script Views
- Full paragraph
- Chunked lines
- One-liner
- Speaker cards
- Cue card view for speeches and sermons

### 6.7 Versioned Script Variants
Maintain script variants such as:

- 30 sec cut
- 60 sec cut
- formal version
- creator version
- sermon version
- live version

### 6.8 Take Review Workflow
- Review multiple takes
- See take notes
- Star best take
- Resume from last failed sentence

### 6.9 Readability Engine
Automatically reflow long text into more natural prompt chunks to reduce eye movement and improve cadence.

### 6.10 Hook Mode
For creators, the first 3 lines get larger sizing, stronger contrast, and easier delivery support.

---

## 7. AI Feature Set

AI features should be split into launch-safe vs later.

### AI in v1
- Rewrite for brevity
- Simplify wording
- Rephrase awkward lines
- Generate alternate takes
- Split into natural phrase chunks
- Estimate read time
- Highlight likely stumbling points
- Convert wall-of-text into teleprompter format

### AI in v1.5+

#### Tone transforms
- more casual
- more authoritative
- more creator-friendly
- more conversational

#### Platform transforms
- TikTok
- Reels
- YouTube
- webinar
- keynote

#### Additional AI features
- Emphasis suggestions
- Filler-word cleanup
- Caption generation from recording
- Delivery coaching summary

### AI Constraints
- AI should assist, not dominate
- Primary experience must still work fully offline except cloud AI features
- AI usage must be clearly optional

---

## 8. UX and Visual Design Direction

### Design Keywords
- cinematic
- luxury black and glass
- Apple-native
- calm
- confident
- creator-grade
- uncluttered

### Product References
The feel should combine:

- iPhone Camera’s confidence and clarity
- Final Cut’s pro restraint
- Notion’s readability and hierarchy
- Captions or Halide-style creator polish

### Visual System

#### Colors
- Primary: true black, graphite, near-black glass
- Accent: subtle white, cool silver, optional warm gold or electric blue accent

#### States
- active follow = soft blue
- listening = cool white pulse
- low confidence = amber
- recording = refined red

#### Materials
- frosted glass panels
- thin separators
- soft glows, not neon
- high-contrast text
- large rounded cards
- restrained motion

#### Typography
- SF Pro / New York mix if desired
- large, elegant headings
- ultra-readable prompt text
- strong numeric typography for timer and speed

### UX Philosophy
- Opinionated defaults
- Advanced controls hidden behind a clean “Tune” panel
- Zero clutter while recording
- Every primary screen should feel calming, not technical

---

## 9. Information Architecture

### Main Tabs

#### 1. Home
- recent scripts
- new script
- import script
- continue last session
- suggested modes

#### 2. Scripts
- all scripts
- folders or projects
- variants
- search

#### 3. Record
- quick camera-overlay setup
- recent recording sessions
- mode preset chooser

#### 4. Practice
- rehearse
- practice stats
- flagged lines

#### 5. Settings
- prompting defaults
- speech-follow preferences
- export
- accessory setup
- AI preferences
- subscription / upgrade

---

## 10. Primary User Flows

### Flow A: Quick Creator Recording
1. Open app
2. Tap **Paste Script**
3. Choose **Record with Overlay**
4. App auto-formats script into readable chunks
5. User sees lens-near text
6. Countdown starts
7. Speech-aware mode follows user
8. User taps jump-back after mistake
9. Finish recording
10. Review takes and export

### Flow B: Traditional Teleprompter Speech
1. Open script
2. Tap **Prompt**
3. Choose:
   - manual speed
   - timed
   - speech-aware
4. Enable mirroring if using rig
5. Start prompting
6. Pause or jump via remote or keyboard

### Flow C: Practice Mode
1. Open script
2. Tap **Practice**
3. Select exact or smart follow
4. Speak through script
5. App marks stumbles and timing issues
6. Review flagged lines

### Flow D: AI Cleanup
1. Paste raw draft
2. Tap **Make Promptable**
3. AI returns:
   - shorter phrasing
   - chunked lines
   - emphasis suggestions
4. Save as a new variant

---

## 11. Functional Requirements

### Script Editor
- Must support rich text
- Must autosave locally
- Must preserve imported formatting as much as practical
- Must allow teleprompter-specific cues not visible in exported plain text

### Prompt Engine
- Must support smooth 60 fps rendering on supported hardware
- Must maintain scroll precision across dynamic type sizes and orientations
- Must allow deterministic timed mode

### Speech-Aware Engine
- Must use on-device speech APIs where possible
- Must maintain current script position state
- Must compare recognized speech against target script buffer
- Must support exact and fuzzy matching
- Must degrade gracefully into manual mode
- Must never unexpectedly jump multiple paragraphs without strong confidence

### Camera Module
- Must support front and back cameras
- Must support prompt overlay with readable contrast
- Must allow focus and exposure lock
- Must save recordings reliably even on interruption where possible

### Remote Input
- Must support hardware keyboard
- Should support controller input
- Should support accessible large tap controls

---

## 12. Non-Functional Requirements

- Launch to usable state in under 2 seconds on modern devices
- Prompt scrolling must remain smooth under load
- Recording sessions should survive transient interruptions as safely as possible
- Local-first script storage
- Privacy-forward onboarding
- Full VoiceOver and Dynamic Type compatibility outside core prompt canvas
- Excellent landscape support on iPad
- No forced account creation in MVP

---

## 13. Suggested Technical Architecture for Swift/iOS

### Recommended Stack
- SwiftUI for app UI
- AVFoundation for recording, preview, camera controls
- Speech framework for on-device speech recognition where available
- Core Data or SwiftData for local persistence
- FileImporter / UIDocumentPicker for imports
- StoreKit 2 for monetization

### Optional Technologies
- Vision or text layout utilities for readability heuristics
- Core ML later for custom phrase alignment or delivery scoring

### Architecture Approach

#### Modular feature domains
- ScriptEditor
- PromptEngine
- SpeechFollowEngine
- CameraRecording
- AIService
- Billing
- Settings

#### Clear state machine for prompt session
- idle
- countdown
- manual scrolling
- speech-follow active
- low-confidence assist
- paused
- recording
- completed

### High-Risk Technical Areas
- speech-follow accuracy under real-world noise
- overlay legibility over live camera feed
- matching paraphrased speech to script position
- smooth performance on older iPads
- floating overlay mode limitations imposed by iOS

---

## 14. Monetization Recommendation

Do not lead with a hard paywall-heavy subscription-only model.

The category already has visible subscription fatigue. Some users explicitly praise one-time purchase options, while others complain about expensive annual pricing and billing surprise.

### Recommended Model

#### Free tier
- unlimited script creation
- manual prompting
- basic text customization
- basic classic teleprompter mode
- limited recording minutes or watermark-free short exports
- limited AI actions per month

#### Pro monthly / annual
- speech-aware prompting
- camera overlay recording
- advanced formatting
- mirroring and external display tools
- practice mode
- AI rewrite tools
- take review workflow
- captions export
- remote or controller support
- script variants

#### Lifetime unlock
Offer a lifetime option early.

This will help differentiate from competitors and reduce user distrust.

### Monetization Principle
**Charge for power, not for basic trust.**

---

## 15. MVP vs Later Roadmap

### MVP
- iPhone + iPad
- script creation and import
- classic teleprompter mode
- camera overlay recording mode
- mirroring or reverse text
- basic remote keyboard support
- strict + smart speech-follow beta
- focus window mode
- jump-back
- rich formatting
- AI prompt cleanup
- elegant black and glass UI

### v1.5
- practice mode
- take comparison
- script variants
- controller support
- caption export
- secondary-device remote

### v2
- Apple Watch remote
- collaborative scripts
- live streaming integrations
- desktop companion
- performance analytics
- coaching insights

---

## 16. Acceptance Criteria for a Coding Agent

### Script Import
- User can import TXT, RTF, PDF, DOCX from Files
- Imported script is editable
- Script persists after app relaunch

### Classic Prompt Mode
- User can open a script and start scrolling within 2 taps
- Text size, speed, margins, and background can be changed live
- Mirroring works correctly in portrait and landscape

### Camera Overlay Mode
- User can record video with prompt text visible near the lens
- Prompt remains legible against camera preview
- Recording saves reliably to Photos or app library

### Speech-Follow Mode
- In strict mode, recognized spoken words advance the script accurately
- In smart mode, small filler words and paraphrasing do not break the experience
- If recognition confidence falls, UI enters assist state instead of jumping erratically

### Jump-Back
- User can jump back by sentence or cue during prompt or recording
- Restarting does not require resetting the full session

### Rich Formatting
- Bold, italic, underline, headings, and pause markers persist after save
- Prompt renderer respects formatting rules without clutter

### AI Cleanup
- User can transform raw text into chunked teleprompter format
- AI output is saved as a new variant without overwriting the original

### iPad Quality
- Landscape support is robust
- Rotation behavior is stable during setup and performance
- Large-format rig use feels intentional, not stretched phone UI

---

## 17. Biggest Strategic Recommendation

Do not frame this as “a teleprompter with lots of features.”

Frame it as:

> **A confidence-first speaking app that helps you look natural on camera.**

That gives ScriptSeer room to outgrow the category:

- teleprompter
- rehearsal tool
- speaking coach
- creator recording assistant
- script optimizer

That is a much bigger brand than “utility app with scrolling text.”
