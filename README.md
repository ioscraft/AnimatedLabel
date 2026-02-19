# AnimatedLabel

A UIKit component that animates text changes character-by-character using spring physics. Each character is individually tracked and animated, creating fluid morphing and replacement effects.

https://github.com/user-attachments/assets/f834eef6-60df-4315-bdfd-6abadd3e52c9

## Installation

Add the package via Swift Package Manager:

```
https://github.com/user/AnimatedLabel.git
```

Or add it as a local package dependency in Xcode.

**Requirements:** iOS 15+, Swift 5.9+

## Usage

```swift
let label = AnimatedLabel()
label.font = .systemFont(ofSize: 22, weight: .bold)
label.textColor = .label
label.setText("Hello")

// Later — characters animate to new text
label.setText("World")
```

`AnimatedLabel` is a `UIView` subclass that supports Auto Layout. It sizes itself via `intrinsicContentSize` using `defaultHigh` priority constraints, so it works naturally in stack views and constraint-based layouts.

### Animating alongside layout changes

When the label is inside a container that needs to resize (e.g. a pill shape), pass an `alongside` closure:

```swift
label.setText("New text") {
    self.view.layoutIfNeeded()
}
```

This runs your layout update in sync with the character spring animations.

## API

### Mode

Controls how characters are matched between the old and new text.

```swift
label.mode = .morph   // default
label.mode = .replace
```

| Mode | Behavior |
|------|----------|
| `.morph` | Characters are matched by identity. Shared characters slide to their new position. |
| `.replace` | Characters are matched by position. Every position runs a full exit/enter transition. |

### Transition

Controls the visual effect for entering and exiting characters.

```swift
label.transition = .scale   // default
label.transition = .rolling
label.transition = .slide
```

| Transition | Effect |
|------------|--------|
| `.scale` | Characters fade in/out with a subtle scale. |
| `.rolling` | Characters slide vertically with scale and fade. Direction is auto-detected from numeric values. |
| `.slide` | Characters slide horizontally with fade. |

### Style

Controls spring physics and timing. Includes three presets:

```swift
label.style = .snappy  // default — responsive, minimal overshoot
label.style = .smooth  // softer spring, longer stagger
label.style = .bouncy  // visible overshoot, playful feel
```

Create a custom style by specifying spring and timing parameters:

```swift
label.style = AnimationStyle(
    mass: 1,
    stiffness: 500,
    damping: 30,
    stagger: 0.05,
    fadeDuration: 0.2
)
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mass` | Spring mass | `1` |
| `stiffness` | Spring stiffness | `350` |
| `damping` | Spring damping | `30` |
| `stagger` | Delay between each character's fade-in | `0.035` |
| `fadeDuration` | Duration of enter/exit fades | `0.15` |

### Other Properties

```swift
label.font = .systemFont(ofSize: 17)  // updates all characters
label.textColor = .label               // updates all characters
label.letterSpacing = 2                // additional spacing between characters
label.drift = 10                       // distance for rolling/slide transitions
```

## Combining Modes and Transitions

Some natural pairings:

- **`.morph` + `.scale`** — Shared characters reposition smoothly, new ones pop in. Good for related words.
- **`.replace` + `.rolling`** — Every character rolls out and in. Good for counters and tickers.
- **`.replace` + `.slide`** — Full horizontal slide replacement. Good for cycling through labels.

All combinations work — mix and match to find what fits your UI.

## Example

The included `AnimatedLabelExample` app demonstrates all modes, transitions, and styles with an interactive UI.
