Based on current App Store leaders, the market already has strong coverage for classic scrolling, mirroring for physical rigs, in-app recording, remote control, and some version of voice-following. Teleprompter Pro emphasizes mirroring, remotes, multi-device control, captions, and recording; Teleprompter.com pushes recording, live streaming, AI rephrasing, and subtitle generation; PromptSmart differentiates around speech-following; and Teleprompter for Video is positioned around reading while recording. The opportunity is not “add a teleprompter,” but “make the most natural, camera-first, trustworthy teleprompter.”
The most important product gap is reliability and naturalness in speech-aware prompting. Existing apps already market voice-following heavily, but user reviews still complain about scroll failures, stopped listening, orientation issues, reload friction, and subscription frustration. That gives you a real opening: better eye-contact UX, more reliable speech-aware pacing, and a more tasteful business model.
PRD — iOS Teleprompter App
Working title
Promptly
Backup directions: GlassCue, LensLine, TruePrompt, Closer.
Product vision
Build the most natural way to read on camera without looking like you’re reading.
This app should feel equally useful for:
creators recording short-form video,
speakers practicing or delivering talks,
actors filming self-tapes,
clergy giving sermons,
professionals recording updates,
educators and livestream hosts.
Positioning
Most teleprompter apps feel like utilities. This should feel like a confidence tool.
Positioning statement:
A beautiful teleprompter and camera-overlay app that helps everyday people and creators speak naturally, maintain eye contact, and get better takes faster.
Product principles
Natural over flashy
Every feature should reduce the feeling of “I’m obviously reading.”
Beginner-friendly by default
Opinionated defaults, low setup friction, clean UI.
Pro-capable under the hood
Mirroring, remotes, advanced formatting, rig support.
Reliable enough for real takes
Speech-aware prompting must fail gracefully.
Private where possible
Speech tracking should work on-device first.

1. Goals
   Primary goals
   Help users read naturally while maintaining near-camera eye contact.
   Support both traditional teleprompter mode and camera-overlay recording mode.
   Offer best-in-class speech-aware prompting.
   Make the app feel premium and beautiful without becoming hard to use.
   Serve both iPhone and iPad well from v1.
   Success criteria
   Users can create/import a script and start prompting in under 60 seconds.
   Users can successfully complete a recording session without learning advanced settings.
   Speech-aware prompting feels helpful, not unpredictable.
   Overlay mode materially improves on-camera delivery.
   App Store feedback mentions polish, ease, and natural eye contact.
2. Target users
   Primary user segments
3. Everyday creators
   TikTok, Reels, YouTube Shorts, talking-head content, ads, UGC.
4. Professional communicators
   Work presentations, async updates, webinars, course content, meetings.
5. Performance/speaking users
   Actors, audition self-tapes, clergy, educators, public speakers.
   Core jobs to be done
   “Help me record without memorizing every line.”
   “Help me look at the camera while reading.”
   “Help the script move at my pace.”
   “Help me recover quickly when I mess up.”
   “Help me get a usable take fast.”
6. Competitive insight
   What incumbents already do well
   Current leaders already cover:
   script import,
   font/speed controls,
   mirroring,
   remote control,
   in-app recording,
   captions/subtitles,
   some speech-following,
   live streaming in some cases.
   Where your app can win
   A. Better speech-aware prompting
   PromptSmart is the clearest speech-following incumbent, but review evidence across the category shows reliability matters more than just having the feature.
   B. Better “reading without looking like reading”
   PromptSmart explicitly mentions narrowing margins to reduce eye tracking, and some users praise when teleprompter text sits close enough to the lens to appear natural. That means the real battleground is not just scrolling text, but eye-motion design.
   C. Better pricing trust
   There are clear complaints in the category around aggressive subscriptions, billing surprise, and weak value perception. A friendlier pricing model is a product advantage, not just a revenue choice.
7. Product scope
   Platforms
   iPhone: fully supported at launch
   iPad: fully supported at launch
   Orientation support:
   portrait
   landscape
   locked orientation per project/session
   Future:
   Mac companion / desktop script editor
   Apple Watch remote
   multi-device controller mode
   Core modes
8. Classic Teleprompter Mode
   A full-screen prompting experience for practice, speeches, rigs, and mirror-glass setups.
9. Camera Overlay Recording Mode
   Record directly in-app with script positioned close to lens.
10. Floating Overlay Mode
    Where technically feasible on iPad/iPhone, allow script overlay over supported use cases; if full system-wide overlay is restricted by iOS, support the closest possible alternative:
    Picture-in-picture style helper where allowed,
    side-by-side workflow on iPad,
    external-display/controller modes,
    “import into app, record here” as the primary fallback.
    Important note for engineering: iOS does not allow arbitrary Android-style always-on-top overlays across other apps in the same way. Any “floating overlay” promise should be scoped carefully around what Apple actually permits. This needs product copy that is precise and not misleading. This is an engineering and product-marketing constraint, not a nice-to-have. (This point is based on platform behavior, not a cited web claim.)
11. MVP feature set
    5.1 Script creation and management
    Create script in-app
    Paste script from clipboard
    Import from:
    TXT
    RTF
    PDF
    DOCX
    Folder/project organization
    Recents
    Duplicate script
    Version history for script revisions
    Autosave
    Search scripts
    Offline local storage by default
    Optional cloud sync later
    5.2 Rich script formatting
    Bold
    Italic
    Underline
    Headings
    Paragraph spacing
    Beat / pause markers
    Emphasis highlighting
    Speaker labels
    Section dividers
    Cue points / bookmarks
    Inline comments/notes hidden during performance
    Estimated duration
    5.3 Prompt controls
    Manual scroll speed
    Timed scroll mode
    Start delay / countdown
    Tap to play/pause
    Scrub/jump to section
    Swipe back one sentence / one paragraph
    Adjustable margins
    Text size
    Line spacing
    Contrast themes
    Mirrored text / horizontal reversal
    Vertical flip for rig workflows if useful
    One-line mode
    Two-line mode
    Chunk mode
    Paragraph mode
    5.4 Speech-aware prompting
    Two modes:
    Strict mode
    Word-by-word alignment
    Best for rehearsed exact scripts
    Smart mode
    Phrase-level matching
    Tolerates:
    filler words
    small paraphrases
    skipped phrases
    pauses
    ad-libs
    re-entry after going off-script
    Fallback behavior
    If confidence drops below threshold:
    pause auto-follow
    show subtle “manual assist” state
    allow user to nudge forward/back
    never wildly jump unless confidence is very high
    UX goals
    Start/stop with natural pacing
    No sudden speed spikes
    Smooth visual catch-up
    Transparent state indicator:
    Listening
    Following
    Low confidence
    Manual mode
    5.5 Camera recording
    Front and rear camera support
    1080p / 4K options where available
    Frame rate options later
    Pause/resume recording
    Multiple takes per script
    Retake from last sentence
    Take naming
    Save to library
    Export video
    Optional clean feed + prompted feed metadata
    Audio input selection if feasible
    Bluetooth mic support
    Exposure/focus lock
    Safe area guides
    Center framing guides
    5.6 Eye-contact optimization
    This is your real wedge.
    Features
    Lens-near text anchoring
    Adjustable vertical prompt offset
    Center-focus reading zone
    Short line wrapping
    Current phrase highlight
    De-emphasized past/future lines
    “Focus Window” mode that only shows the current sentence or phrase
    “Glance-minimizing layout” presets:
    selfie
    webinar
    speech
    audition
    5.7 Remote and accessory support
    Bluetooth keyboard shortcuts
    Game controller support
    Simple remote actions:
    play/pause
    faster/slower
    next/previous cue
    Apple Watch support later
    Secondary-device controller later
    External display support later
    5.8 Teleprompter rig support
    Mirror/reverse text
    External display output
    Large text optimization for iPad
    Landscape-first rig mode
    Optional black background high-contrast mode
12. Differentiation features
    These are the features most likely to make the app genuinely stand out.
    6.1 Focus Window Mode
    Only the current thought is shown near the lens, with surrounding text minimized.
    Goal: reduce visible eye scanning.
    6.2 Confidence Scroll
    Auto-scroll speed adapts to speaking pace, pauses, and confidence level.
    6.3 Smart Jump Back
    One tap jumps back to the previous sentence, cue, or thought block instead of forcing a full restart.
    6.4 Practice Mode
    Rehearse without recording
    Detect stumbles
    Track pacing
    Mark difficult lines
    Show estimated delivery time
    6.5 Energy Markup
    Users tag lines with:
    emphasize
    smile
    slow down
    pause
    punchline
    sincerity
    Then those cues appear elegantly during prompting.
    6.6 Script Views
    Full paragraph
    Chunked lines
    One-liner
    Speaker cards
    Cue card view for speeches/sermons
    6.7 Versioned Script Variants
    Maintain script variants such as:
    30 sec cut
    60 sec cut
    formal version
    creator version
    sermon version
    live version
    6.8 Take Review Workflow
    Review multiple takes
    See take notes
    Star best take
    Resume from last failed sentence
    6.9 Readability Engine
    Automatically reflow long text into more natural prompt chunks to reduce eye movement and improve cadence.
    6.10 Hook Mode
    For creators: first 3 lines get larger sizing, stronger contrast, and easier delivery support.
13. AI feature set
    You said yes to all AI features. I would split them into launch-safe vs later.
    AI in v1
    Rewrite for brevity
    Simplify wording
    Rephrase awkward lines
    Generate alternate takes
    Split into natural phrase chunks
    Estimate read time
    Highlight likely stumbling points
    Convert wall-of-text into teleprompter format
    AI in v1.5+
    Tone transforms:
    more casual
    more authoritative
    more creator-friendly
    more conversational
    Platform transforms:
    TikTok
    Reels
    YouTube
    webinar
    keynote
    Emphasis suggestions
    Filler-word cleanup
    Caption generation from recording
    Delivery coaching summary
    AI constraints
    AI should assist, not dominate
    Primary experience must still work fully offline except cloud AI features
    AI usage must be clearly optional
14. UX / visual design direction
    Design keywords
    cinematic
    luxury black/glass
    Apple-native
    calm
    confident
    creator-grade
    uncluttered
    Product references
    The feel should combine:
    iPhone Camera’s confidence and clarity,
    Final Cut’s pro restraint,
    Notion’s readability and hierarchy,
    Captions/Halide-style creator polish.
    Visual system
    Colors
    Primary: true black / graphite / near-black glass
    Accent: subtle white, cool silver, optional warm gold or electric blue accent
    States:
    active follow = soft blue
    listening = cool white pulse
    low confidence = amber
    recording = refined red
    Materials
    frosted glass panels
    thin separators
    soft glows, not neon
    high-contrast text
    large rounded cards
    restrained motion
    Typography
    SF Pro / New York mix if desired
    large, elegant headings
    ultra-readable prompt text
    strong numeric typography for timer/speed
    UX philosophy
    Opinionated defaults
    Advanced controls hidden behind a clean “Tune” panel
    Zero clutter while recording
    Every primary screen should feel calming, not technical
15. Information architecture
    Main tabs
16. Home
    recent scripts
    new script
    import script
    continue last session
    suggested modes
17. Scripts
    all scripts
    folders/projects
    variants
    search
18. Record
    quick camera-overlay setup
    recent recording sessions
    mode preset chooser
19. Practice
    rehearse
    practice stats
    flagged lines
20. Settings
    prompting defaults
    speech-follow preferences
    export
    accessory setup
    AI preferences
    subscription / upgrade
21. Primary user flows
    Flow A: Quick creator recording
    Open app
    Tap “Paste Script”
    Choose “Record with Overlay”
    App auto-formats script into readable chunks
    User sees lens-near text
    Countdown starts
    Speech-aware mode follows user
    User taps jump-back after mistake
    Finish recording
    Review takes and export
    Flow B: Traditional teleprompter speech
    Open script
    Tap “Prompt”
    Choose:
    manual speed
    timed
    speech-aware
    Enable mirroring if using rig
    Start prompting
    Pause or jump via remote/keyboard
    Flow C: Practice mode
    Open script
    Tap “Practice”
    Select exact or smart follow
    Speak through script
    App marks stumbles and timing issues
    Review flagged lines
    Flow D: AI cleanup
    Paste raw draft
    Tap “Make Promptable”
    AI returns:
    shorter phrasing
    chunked lines
    emphasis suggestions
    Save as new variant
22. Functional requirements
    Script editor
    Must support rich text
    Must autosave locally
    Must preserve imported formatting as much as practical
    Must allow teleprompter-specific cues not visible in exported plain text
    Prompt engine
    Must support smooth 60 fps rendering on supported hardware
    Must maintain scroll precision across dynamic type sizes and orientations
    Must allow deterministic timed mode
    Speech-aware engine
    Must use on-device speech APIs where possible
    Must maintain current script position state
    Must compare recognized speech against target script buffer
    Must support exact and fuzzy matching
    Must degrade gracefully into manual mode
    Must never unexpectedly jump multiple paragraphs without strong confidence
    Camera module
    Must support front and back cameras
    Must support prompt overlay with readable contrast
    Must allow focus/exposure lock
    Must save recordings reliably even on interruption where possible
    Remote input
    Must support hardware keyboard
    Should support controller input
    Should support accessible large tap controls
23. Non-functional requirements
    Launch to usable state in under 2 seconds on modern devices
    Prompt scrolling must remain smooth under load
    Recording sessions should survive transient interruptions as safely as possible
    Local-first script storage
    Privacy-forward onboarding
    Full VoiceOver and Dynamic Type compatibility outside core prompt canvas
    Excellent landscape support on iPad
    No forced account creation in MVP
24. Suggested technical architecture for Swift/iOS
    Recommended stack
    SwiftUI for app UI
    AVFoundation for recording, preview, camera controls
    Speech framework for on-device speech recognition where available
    Core Data or SwiftData for local persistence
    FileImporter / UIDocumentPicker for imports
    StoreKit 2 for monetization
    Optional:
    Vision / text layout utilities for readability heuristics
    Core ML later for custom phrase alignment or delivery scoring
    Architecture approach
    Modular feature domains:
    ScriptEditor
    PromptEngine
    SpeechFollowEngine
    CameraRecording
    AIService
    Billing
    Settings
    Clear state machine for prompt session:
    idle
    countdown
    manual scrolling
    speech-follow active
    low-confidence assist
    paused
    recording
    completed
    High-risk technical areas
    speech-follow accuracy under real-world noise
    overlay legibility over live camera feed
    matching paraphrased speech to script position
    smooth performance on older iPads
    floating/overlay mode limitations imposed by iOS
25. Monetization recommendation
    I would not lead with a hard paywall-heavy subscription-only model.
    The category already has visible subscription fatigue. Some users explicitly praise one-time purchase options, while others complain about expensive annual pricing and billing surprise.
    Recommended model
    Free tier
    unlimited script creation
    manual prompting
    basic text customization
    basic classic teleprompter mode
    limited recording minutes or watermark-free short exports
    limited AI actions per month
    Pro monthly / annual
    speech-aware prompting
    camera overlay recording
    advanced formatting
    mirroring and external display tools
    practice mode
    AI rewrite tools
    take review workflow
    captions export
    remote/controller support
    script variants
    Lifetime unlock
    Offer a lifetime option early.
    This will help differentiate from competitors and reduce user distrust.
    Monetization principle
    Charge for power, not for basic trust.
26. MVP vs later roadmap
    MVP
    iPhone + iPad
    script creation/import
    classic teleprompter mode
    camera overlay recording mode
    mirroring/reverse text
    basic remote keyboard support
    strict + smart speech-follow beta
    focus window mode
    jump-back
    rich formatting
    AI prompt cleanup
    elegant black/glass UI
    V1.5
    practice mode
    take comparison
    script variants
    controller support
    caption export
    secondary-device remote
    V2
    Apple Watch remote
    collaborative scripts
    live streaming integrations
    desktop companion
    performance analytics
    coaching insights
27. Acceptance criteria for a coding agent
    Script import
    User can import TXT, RTF, PDF, DOCX from Files
    Imported script is editable
    Script persists after app relaunch
    Classic prompt mode
    User can open a script and start scrolling within 2 taps
    Text size, speed, margins, and background can be changed live
    Mirroring works correctly in portrait and landscape
    Camera-overlay mode
    User can record video with prompt text visible near the lens
    Prompt remains legible against camera preview
    Recording saves reliably to Photos or app library
    Speech-follow mode
    In strict mode, recognized spoken words advance the script accurately
    In smart mode, small filler words and paraphrasing do not break the experience
    If recognition confidence falls, UI enters assist state instead of jumping erratically
    Jump-back
    User can jump back by sentence or cue during prompt or recording
    Restarting does not require resetting the full session
    Rich formatting
    Bold/italic/underline/headings/pause markers persist after save
    Prompt renderer respects formatting rules without clutter
    AI cleanup
    User can transform raw text into chunked teleprompter format
    AI output is saved as a new variant without overwriting original
    iPad quality
    Landscape support is robust
    Rotation behavior is stable during setup and performance
    Large-format rig use feels intentional, not stretched phone UI
28. Biggest strategic recommendation
    Do not frame this as “a teleprompter with lots of features.”
    Frame it as:
    A confidence-first speaking app that helps you look natural on camera.
    That gives you room to outgrow the category:
    teleprompter
    rehearsal tool
    speaking coach
    creator recording assistant
    script optimizer
    That is a much bigger brand than “utility app with scrolling text.”
