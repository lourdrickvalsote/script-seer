# ScriptSeer QA Checklist

## Core Flows

### Script Management
- [ ] Create a new script from Home
- [ ] Create a new script from Scripts tab
- [ ] Edit script title (tap to edit in detail view)
- [ ] Edit script content in editor
- [ ] Duplicate a script (swipe action)
- [ ] Delete a script (swipe action)
- [ ] Search scripts by title
- [ ] Search scripts by content
- [ ] Sort scripts by recent
- [ ] Sort scripts by title
- [ ] Scripts persist across app relaunch
- [ ] Demo scripts can be seeded

### File Import
- [ ] Import TXT file from Files
- [ ] Import RTF file from Files
- [ ] Import PDF file from Files
- [ ] Import DOCX file from Files
- [ ] Failed import shows user-friendly error
- [ ] Empty file import handled gracefully
- [ ] Import available from Home quick actions
- [ ] Import available from Scripts toolbar

### Script Editor
- [ ] Text editing is smooth
- [ ] Formatting toolbar shows/hides
- [ ] Teleprompter cue markers can be inserted
- [ ] Estimated duration updates as content changes
- [ ] Word count updates as content changes
- [ ] Duplicate as variant works from editor menu
- [ ] AI Actions accessible from editor menu
- [ ] Variant browser accessible from editor menu
- [ ] Autosave works (edit, go back, reopen)

### Classic Teleprompter
- [ ] Can start prompting from script detail
- [ ] Countdown works (3, 2, 1)
- [ ] Auto-scroll is smooth
- [ ] Play/pause toggle works (tap and control button)
- [ ] Speed adjustment works in Tune panel
- [ ] Text size adjustment works
- [ ] Line spacing adjustment works
- [ ] Margin adjustment works
- [ ] All 4 display modes work (Paragraph, Two Line, One Line, Chunk)
- [ ] All 4 themes work
- [ ] Mirrored mode works
- [ ] Jump-back works
- [ ] Exit confirmation dialog works
- [ ] Works in portrait orientation
- [ ] Works in landscape orientation

### Focus Window
- [ ] Focus Window toggle in Tune panel
- [ ] Current line highlighted
- [ ] Past/future lines de-emphasized
- [ ] Vertical offset adjustable
- [ ] All 4 presets change layout behavior
- [ ] Focus Window works with mirrored mode

### Camera Recording
- [ ] Camera preview shows
- [ ] Front camera works
- [ ] Rear camera works
- [ ] Camera switching works
- [ ] Script overlay is readable over camera
- [ ] Recording starts with countdown
- [ ] Recording stops and saves
- [ ] Framing guide visible

### Speech Follow
- [ ] Speech permission requested
- [ ] Start/stop speech follow from prompt controls
- [ ] Status indicator shows current state
- [ ] Strict mode advances on word match
- [ ] Smart mode is more tolerant
- [ ] Low confidence state visible
- [ ] No erratic jumps on weak input
- [ ] Manual controls still work with speech active

### Practice Mode
- [ ] Can select a script to practice
- [ ] Practice starts with line-by-line view
- [ ] Stumble button marks current line
- [ ] Next button advances to next line
- [ ] Tap a line to jump to it
- [ ] Done button shows results
- [ ] Results show time, WPM, pace
- [ ] Stumble list shows flagged lines
- [ ] Retry from flagged line works

### AI Actions
- [ ] All 6 AI actions appear in sheet
- [ ] Loading state shown during processing
- [ ] Result preview displayed
- [ ] Save as variant creates new variant
- [ ] Discard returns to action list
- [ ] Original script preserved after AI action
- [ ] Variants browsable in variant browser

### Settings
- [ ] All prompt defaults adjustable
- [ ] Speech follow mode changeable
- [ ] Haptics toggle works
- [ ] Show onboarding tips resets onboarding
- [ ] Pro upgrade view accessible
- [ ] Restore purchases button present

### Onboarding
- [ ] Shows on first launch
- [ ] All 4 pages display correctly
- [ ] Skip button works
- [ ] Get Started button on last page works
- [ ] Onboarding doesn't show again after completion

### Keyboard Shortcuts (iPad with keyboard)
- [ ] Space: play/pause in teleprompter
- [ ] Up arrow: increase speed
- [ ] Down arrow: decrease speed
- [ ] Left arrow: jump back
- [ ] Escape: exit prompt

## Device Compatibility
- [ ] iPhone portrait
- [ ] iPhone landscape
- [ ] iPad portrait
- [ ] iPad landscape
- [ ] iPad split view (basic functionality)

## Known Issues
- Camera features require physical device (not testable in Simulator)
- Speech recognition requires microphone access (limited in Simulator)
- DOCX import uses basic text extraction (complex formatting may be lost)
- AI actions use mock provider (no real AI backend connected yet)
- StoreKit 2 purchase flow is scaffolded but not connected to App Store
