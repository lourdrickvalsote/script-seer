# Floating Overlay Research — iOS/iPadOS Platform Constraints

## Summary

iOS does not support Android-style system-wide floating overlays. Apps cannot render UI on top of other apps. This is a fundamental platform limitation enforced by Apple's sandbox model.

## What IS Possible

### 1. iPad Split View / Slide Over (Best Option)
- ScriptSeer can run side-by-side with a video call app (Zoom, FaceTime, etc.)
- User reads script in ScriptSeer while recording in another app
- Works well on iPad with sufficient screen real estate
- No special API needed — just good iPad layout support
- **Recommendation: Optimize for compact width layouts to be useful in Split View**

### 2. Picture-in-Picture (Limited)
- PiP is for video playback only (AVPlayerLayer or AVPictureInPictureController)
- Cannot display arbitrary text in PiP
- Could theoretically render script as a "video" and play it in PiP, but this is:
  - A UX hack that Apple may reject
  - Poor text quality due to video compression
  - Not recommended for production
- **Recommendation: Do not pursue PiP for text display**

### 3. Secondary Device Controller Mode
- Use a second iPhone/iPad as a remote prompter controller
- Could use MultipeerConnectivity or local network
- One device shows the camera (or connects to a video call), the other runs ScriptSeer
- This is fully supported and compliant
- **Recommendation: Good stretch feature for future development**

### 4. Live Activities / Dynamic Island
- Limited to compact, glanceable info (not suitable for script text)
- Could show "currently prompting" status, but not readable script content
- **Recommendation: Not suitable for teleprompter use case**

### 5. AirPlay / External Display
- Could drive a second screen as a teleprompter
- AVFoundation supports external displays
- Useful for physical teleprompter setups
- **Recommendation: Good niche feature for professional users**

## What is NOT Possible

- System-wide floating overlay windows (Android-only)
- Rendering UI on top of other running apps
- Background audio + floating text overlay
- Notification-based text display during other apps

## Recommended Strategy

1. **Short-term**: Ensure excellent iPad multitasking support (Split View, Slide Over)
2. **Medium-term**: Build secondary device controller mode via MultipeerConnectivity
3. **Long-term**: External display support for professional teleprompter rigs
4. **Do not pursue**: PiP hacks, system overlay workarounds, or anything Apple would reject

## Product Language Update

Avoid promising "overlay on any app" functionality. Instead, position features as:
- "Side-by-side prompting" (iPad Split View)
- "Dual-device prompting" (secondary controller)
- "Professional rig support" (external display)
