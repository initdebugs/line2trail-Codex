# Line2Trail UI Design System

This document defines the visual design language, color scheme, and styling guidelines for the Line2Trail app.

## Design Philosophy

Line2Trail embraces a **modern outdoor** aesthetic that combines:
- Clean, minimalist interfaces for easy navigation
- Nature-inspired colors that feel fresh and energetic
- Bold, readable typography suitable for outdoor use
- Intuitive iconography with outdoor/navigation themes
- Accessibility-first design for various lighting conditions

## Color Palette

### Primary Colors
```
Trail Green (Primary)
- Main: #2E7D32 (Forest Green)
- Light: #66BB6A (Light Green)
- Dark: #1B5E20 (Deep Forest)
- Surface: #E8F5E8 (Light Green Surface)
```

### Secondary Colors
```
Path Blue (Secondary)
- Main: #1976D2 (Navigation Blue)
- Light: #42A5F5 (Sky Blue)
- Dark: #0D47A1 (Deep Blue)
- Surface: #E3F2FD (Light Blue Surface)
```

### Accent Colors
```
Summit Orange (Accent)
- Main: #FF6F00 (Vibrant Orange)
- Light: #FFB74D (Warm Orange)
- Dark: #E65100 (Deep Orange)

Warning Amber
- Main: #FF8F00 (Alert Amber)
- Light: #FFCC02 (Bright Yellow)

Error Red
- Main: #D32F2F (Error Red)
- Light: #F44336 (Alert Red)
```

### Neutral Palette
```
Text Colors
- Primary Text: #212121 (Almost Black)
- Secondary Text: #616161 (Medium Gray)
- Disabled Text: #9E9E9E (Light Gray)
- Inverse Text: #FFFFFF (White)

Background Colors
- Background: #FAFAFA (Off White)
- Surface: #FFFFFF (Pure White)
- Card: #FFFFFF (Card Background)
- Overlay: rgba(0, 0, 0, 0.6) (Dark Overlay)

Border Colors
- Outline: #E0E0E0 (Light Border)
- Divider: #EEEEEE (Subtle Divider)
- Focus: #2E7D32 (Trail Green Border)
```

### Map-Specific Colors
```
Route Colors
- Active Route: #2E7D32 (Trail Green)
- Drawing Route: #FF6F00 (Summit Orange)
- Completed Route: #1976D2 (Path Blue)
- Elevation Gain: #4CAF50 (Success Green)
- Elevation Loss: #FF5722 (Descent Red)

Map UI
- Control Background: rgba(255, 255, 255, 0.9)
- Control Shadow: rgba(0, 0, 0, 0.15)
- Location Marker: #2E7D32 (Trail Green)
- Compass: #1976D2 (Path Blue)
```

## Typography

### Font Family
```
Primary Font: 'Roboto' (Android default)
- Display: Roboto Medium/Bold
- Headings: Roboto Medium
- Body: Roboto Regular
- Captions: Roboto Regular
- Buttons: Roboto Medium
```

### Type Scale
```
Display Large: 36px, Bold, Letter Spacing -0.25px
Display Medium: 28px, Bold, Letter Spacing 0px
Display Small: 24px, Bold, Letter Spacing 0px

Headline Large: 22px, Medium, Letter Spacing 0px
Headline Medium: 20px, Medium, Letter Spacing 0.15px
Headline Small: 18px, Medium, Letter Spacing 0.15px

Title Large: 16px, Medium, Letter Spacing 0.15px
Title Medium: 14px, Medium, Letter Spacing 0.1px
Title Small: 12px, Medium, Letter Spacing 0.1px

Body Large: 16px, Regular, Letter Spacing 0.5px
Body Medium: 14px, Regular, Letter Spacing 0.25px
Body Small: 12px, Regular, Letter Spacing 0.4px

Label Large: 14px, Medium, Letter Spacing 0.1px
Label Medium: 12px, Medium, Letter Spacing 0.5px
Label Small: 10px, Medium, Letter Spacing 0.5px
```

## Component Styling

### Buttons

#### Primary Button (Call-to-Action)
```
Background: Trail Green (#2E7D32)
Text: White (#FFFFFF)
Border Radius: 8px
Height: 48dp
Padding: 16dp horizontal
Typography: Label Large
Shadow: Elevation 2dp
States:
  - Hover: Trail Green Light (#66BB6A)
  - Pressed: Trail Green Dark (#1B5E20)
  - Disabled: Light Gray (#E0E0E0)
```

#### Secondary Button (Navigation)
```
Background: Path Blue (#1976D2)
Text: White (#FFFFFF)
Border Radius: 8px
Height: 48dp
Padding: 16dp horizontal
Typography: Label Large
Shadow: Elevation 1dp
```

#### Outlined Button (Alternative Action)
```
Background: Transparent
Text: Trail Green (#2E7D32)
Border: 1dp solid Trail Green (#2E7D32)
Border Radius: 8px
Height: 48dp
Padding: 16dp horizontal
Typography: Label Large
```

#### Text Button (Subtle Action)
```
Background: Transparent
Text: Trail Green (#2E7D32)
Padding: 12dp horizontal, 8dp vertical
Typography: Label Large
Min Touch Target: 48dp x 48dp
```

### Cards and Surfaces

#### Elevated Card (Route Cards)
```
Background: White (#FFFFFF)
Border Radius: 12dp
Shadow: Elevation 2dp
Padding: 16dp
Border: None
```

#### Outlined Card (Secondary Content)
```
Background: White (#FFFFFF)
Border: 1dp solid Outline (#E0E0E0)
Border Radius: 8dp
Padding: 16dp
Shadow: None
```

### Input Fields

#### Text Input
```
Background: Surface (#FFFFFF)
Border: 1dp solid Outline (#E0E0E0)
Border Radius: 8dp
Height: 48dp
Padding: 16dp horizontal, 14dp vertical
Typography: Body Large
Focus Border: 2dp solid Trail Green (#2E7D32)
Error Border: 2dp solid Error Red (#D32F2F)
```

#### Search Bar
```
Background: Light Green Surface (#E8F5E8)
Border Radius: 24dp
Height: 40dp
Padding: 12dp horizontal
Typography: Body Medium
Icon: Medium Gray (#616161)
```

### Navigation

#### Bottom Navigation Bar
```
Background: White (#FFFFFF)
Height: 64dp
Border Top: 1dp solid Divider (#EEEEEE)
Active Icon: Trail Green (#2E7D32)
Inactive Icon: Medium Gray (#616161)
Active Text: Trail Green (#2E7D32)
Inactive Text: Medium Gray (#616161)
Typography: Label Small
```

#### Top App Bar
```
Background: White (#FFFFFF)
Height: 56dp
Title Typography: Headline Small
Title Color: Primary Text (#212121)
Icon Color: Medium Gray (#616161)
Shadow: Elevation 1dp
```

### Map Controls

#### Floating Action Button (Map Controls)
```
Background: White with 90% opacity
Size: 48dp x 48dp
Border Radius: 24dp
Icon Size: 24dp
Icon Color: Primary Text (#212121)
Shadow: Elevation 3dp
Position: 16dp from edges
```

#### Map Control Panel
```
Background: White with 90% opacity
Border Radius: 8dp
Padding: 8dp
Shadow: Elevation 2dp
Backdrop Filter: Blur 10px
```

### Activity Mode Chips

#### Active Chip
```
Background: Trail Green (#2E7D32)
Text: White (#FFFFFF)
Border Radius: 16dp
Height: 32dp
Padding: 12dp horizontal
Typography: Label Medium
```

#### Inactive Chip
```
Background: Light Green Surface (#E8F5E8)
Text: Trail Green (#2E7D32)
Border Radius: 16dp
Height: 32dp
Padding: 12dp horizontal
Typography: Label Medium
```

## Spacing System

### Base Unit: 4dp

```
Micro:    2dp  (0.5x)
Small:    4dp  (1x)
Medium:   8dp  (2x)
Large:    12dp (3x)
XLarge:   16dp (4x)
XXLarge:  24dp (6x)
Huge:     32dp (8x)
Massive:  48dp (12x)
```

### Layout Margins
```
Screen Edge: 16dp
Card Margins: 16dp
Section Spacing: 24dp
Component Spacing: 8dp
Text Line Height: 1.4x font size
```

## Iconography

### Icon Style
- **Style**: Outlined icons (Material Design)
- **Weight**: 400 (Regular)
- **Size Standards**: 16dp, 20dp, 24dp, 32dp
- **Color**: Inherit from parent or use semantic colors

### Custom Icons (Trail-Specific)
```
Trail Types:
- Hiking Boot: Hiking routes
- Bicycle: Cycling routes
- Running Shoe: Running routes
- Walking Person: Walking routes

Navigation:
- Compass Rose: Navigation mode
- Route Pin: Waypoints
- Elevation Chart: Elevation profile
- GPS Signal: Location services

Actions:
- Pencil Path: Draw mode
- Download Cloud: Offline maps
- Share Arrow: Export/Share
- Bookmark: Save route
```

## Accessibility Guidelines

### Color Contrast
- Text on background: Minimum 4.5:1 ratio
- Large text (18dp+): Minimum 3:1 ratio
- Interactive elements: Minimum 3:1 ratio
- Focus indicators: Minimum 3:1 ratio

### Touch Targets
- Minimum size: 48dp x 48dp
- Spacing: 8dp between adjacent targets
- Map controls: 56dp x 56dp for outdoor use

### Typography
- Minimum text size: 12dp
- Outdoor readability: 14dp+ recommended
- High contrast mode support
- Dynamic font scaling support

## Dark Mode Variants

### Dark Color Palette
```
Primary: #4CAF50 (Brighter Green for contrast)
Surface: #1E1E1E (Dark Gray)
Background: #121212 (Almost Black)
On-Surface: #E1E1E1 (Light Gray Text)
Card: #2A2A2A (Dark Card)
```

### Dark Mode Guidelines
- Increase primary color luminance by 20%
- Use darker surface colors with subtle elevation
- Maintain contrast ratios for accessibility
- Test in various lighting conditions

## Implementation Notes

### Flutter Theme Structure
```dart
// Primary theme data structure
ThemeData(
  colorScheme: ColorScheme.light(
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF1976D2),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFFAFAFA),
    // ... additional colors
  ),
  // Component themes
  appBarTheme: AppBarTheme(...),
  elevatedButtonTheme: ElevatedButtonThemeData(...),
  // ... other component themes
)
```

### Design Token Organization
- Create constants file for all colors
- Use semantic naming (primary, secondary, success)
- Implement theme switching for day/night modes
- Test across different Android versions and screen sizes