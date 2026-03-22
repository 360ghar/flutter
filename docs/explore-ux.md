# Explore View UX Design

## Overview

The Explore page combines an interactive map with a horizontal property card carousel. Users browse properties both spatially (via map markers) and linearly (via the card list), with bidirectional synchronization between the two views.

## Collapsible Property List

### Architecture

The bottom property list uses `AnimatedPositioned` to toggle between expanded and collapsed states.

- **Expanded**: `bottom: 0` — 44px handle + 220px card list visible (264px total)
- **Collapsed**: `bottom: -220` — only 44px handle strip visible above safe area
- **State**: `ExploreController.isListCollapsed` (`RxBool`)
- **Animation**: 300ms (`AppDurations.normal`), easeOutCubic (`AppCurves.standard`)

### Handle Strip (44px)

- Rounded top corners (16px radius) — bottom-sheet visual language
- `warmCream` bg at 95% opacity (dark: `darkSurfaceAlt`)
- 3-side border (top/left/right) in `editorialWarm` 0.3 alpha
- Centered 36x4px drag handle bar
- Property count text with chevron icon (up when collapsed, down when expanded)

### Interactions

| Action | Result |
|--------|--------|
| Tap handle | Toggle collapse/expand |
| Swipe up on handle | Expand list |
| Swipe down on handle | Collapse list |
| Tap map marker while collapsed | Auto-expand + scroll to selected card |

### Auto-Expand on Marker Tap

When a user taps a map marker while the list is collapsed:
1. `selectProperty()` sets `isListCollapsed = false`
2. `AnimatedPositioned` begins sliding list up (300ms)
3. Simultaneously, the `ever()` worker fires `_scrollToProperty()` — the card scrolls to center position AS the list animates upward
4. Haptic feedback (`selectionClick`) confirms the interaction

This coordinated animation creates a polished entrance effect.

## Map-List Bidirectional Sync

### List Scroll → Map Highlight

1. User scrolls the horizontal property list
2. `_onScroll()` debounces at 80ms, calculates which card is most visible
3. Calls `highlightPropertyFromCard()` which sets `selectedProperty`
4. Map marker rebuilds with `isSelected: true` — gold background + pulse animation
5. No camera movement (intentional — avoids fighting user's map focus)

### Map Marker Tap → List Scroll

1. User taps a property marker on the map
2. `selectProperty()` updates `selectedProperty` (and auto-expands if collapsed)
3. `ever()` worker in `PropertyHorizontalList` fires
4. `_scrollToProperty()` centers the card in the viewport with 300ms animation
5. `HapticFeedback.selectionClick()` provides tactile confirmation

### Scroll Centering

Cards scroll to the center of the viewport (not left edge):
```
target = index * (itemWidth + spacing) - (viewportWidth / 2) + (itemWidth / 2)
```

## Compact Info Panel

The top-left info panel shows property count and search radius in a single-line pill format:

**Format**: `15 properties · 5.0 km radius`

- Count: Playfair Display 16pt bold
- Label + separator + radius: DM Sans 11pt
- Padding: 12px horizontal, 8px vertical
- ~32px tall (was ~70px in the multi-line version)

The location name was removed because it duplicates the `LocationSelector` in the top bar.

## Animation Specifications

| Animation | Duration | Curve | Trigger |
|-----------|----------|-------|---------|
| List collapse/expand | 300ms | easeOutCubic | Handle tap, marker tap |
| Card scroll to selection | 300ms | easeOutCubic | Marker tap, list scroll |
| Card highlight border | 200ms | linear | Selection change |
| Marker pulse | 1400ms | linear (repeat) | Selection |

## Dark Mode

All components use `AppDesignTokens` for theme-aware colors:

| Element | Light | Dark |
|---------|-------|------|
| Handle bg | `warmCream` 95% | `darkSurfaceAlt` 95% |
| Handle border | `editorialWarm` 30% | `darkBorder` |
| Handle bar | `neutral300` | `darkBorder` |
| Handle text | `editorialInk` 60% | `darkTextSecondary` |
| Info panel bg | `warmCream` 95% | `darkSurfaceAlt` 95% |
| Info panel border | `editorialWarm` 30% | `darkBorder` |

## Accessibility

- Handle strip has `Semantics(label: 'expand/collapse_property_list', button: true)`
- Property count announced in collapsed handle text
- Haptic feedback on selection changes

## Future Considerations

- **Camera nudge**: When list-scroll highlights a property outside the visible map bounds, gently pan the camera to keep the marker visible (40% toward property, not full recenter)
- **Edge indicator**: Show a directional arrow at the map edge when selected property is off-screen
- **Snap-to-center**: PageView-style snapping was considered but rejected — free scrolling with 80ms debounce highlight feels more natural for browsing
