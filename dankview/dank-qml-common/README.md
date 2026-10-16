# dank-qml-common

Common QML assets for DMS, Dank Calendar, and the rest of the Dank Linux Suite.

The library lives in `DCommon/` and is consumed through Quickshell's `qs.` namespace:

```qml
import qs.DCommon.Widgets
import qs.DCommon.Common
import qs.DCommon.FileBrowser
import qs.DCommon.Session
```

`DCommon/Session/` holds the components shared between the DMS lock screen and [dms-greeter](https://github.com/AvengeMedia/dank-greeter): the power menu (`LockPowerMenu`) and the on-screen keyboard (`Keyboard`, `KeyboardController`, `CustomButtonKeyboard`). `LockMetrics`, `LockActionButton`, and `LockNotificationCard` provide reusable lock-screen geometry and surfaces. `PowerMenuView` supplies the shared grid/list controls for the shell and lock power menus. `KeyboardController.expressive` and `LockPowerMenu.expressive` opt into Expressive styling; both default to `false`.

`DCommon/FileBrowser/` is the file browser shared with Dank Files, backed by `Host.files` (see the contract). `FilePicker` is the dialog body: `mode` (`open`, `openFolder`, `save`), `filters` (globs), `multiple`, `defaultName`, `startPath` (a directory opens it, a file opens its folder and selects it), `bucket` (the key its view mode, sort, zoom, hidden toggle and last folder persist under in `Host.cache.fileBrowserSettings`), signals `accepted(paths)` and `rejected`. `FileBrowserModal` hosts it in a floating window and keeps the old names (`browserTitle`, `browserType`, `fileExtensions`/`filterExtensions`, `showHiddenFiles`, `saveMode`, `folderMode`, `defaultFileName`, `revealPath`, `parentModal`, `fileSelected(path)`, `dialogClosed`) mapped onto it; `fileSelected` carries a plain path in every mode. `FileBrowserView` is the browser without dialog behaviour (sidebar of user dirs, back/forward, path bar, list and grid views, selection, keyboard, rubber band, inline rename, extra toolbar items as children), and its parts (`DirectoryModel`, `SelectionModel`, `NavigationHistory`, `FileViewBody`, `FileListView`, `FileGridView`, `FileRow`, `FileTile`, `PathBar`, `NavButtonPair`, `FilePlaceRow`, `FileMenu`, `FileSortButton`) are usable on their own. A host can put its own item at the end of the path bar row through `pathBarTrailing`, and handle `tabRequested(path)` (middle click on a folder, a column entry or a path pill) and `pathMenuRequested(path, x, y)` (right click on a pill); `revealAndRename(path)` selects an item once it is listed and starts inline rename. A host that draws a location itself sets `unlistedPath`: the browser keeps that path in its history but never lists or watches it. `FileColumns.trashColumns` holds the `origin` and `deleted` list columns, which read `originalPath` and `deletedMs` from the row's model entry. `FileSortButton.keys` replaces the offered sort keys (`{key, icon, label}`); `defaultKeys` holds the folder ones. The path bar takes what the backend's `resolveLocation` accepts and hands remote and server locations to the host through `locationRequested(location)`; the host calls `settleLocation(path)` when the connection finished (an empty path when it failed) and gets `locationCancelled` when the user gave up. `folderJump` is an optional object with `match(query, limit, exclude)` and `top(limit, exclude)` returning `[{path, display, positions}]` without the open folder `exclude`, `forget(path)` and `verify(paths)`; with it, words that are not a path suggest visited folders, and `startJump()` opens the bar empty with the top ones. Folder drop targets report the hovered folder, pointer and Qt's proposed drop action to `FileDragHover`, so a host can show what a drop would do. `FileBrowserSettings.load(bucket)` and `save(bucket, patch)` are the only readers and writers of the persisted records.

`FilePreviewPane` previews the first of `entries` on a rounded tonal card: icon, name, details and the viewer's content. With `closable` it shows a close button in its corner that emits `closeRequested`. It copies the entry into a plain object one event-loop turn after it changes (and on `sourceModel` row changes), then loads content right away when the cursor arrives after a pause, or `FileBrowserMetrics.settleInterval` after the last of a quick run of moves; until it is ready, an image, SVG or thumbnail preview shows the list thumbnail at the size the content will take; a change of only mtime or size refreshes at most every `previewRefreshInterval` and keeps the old content up meanwhile. It picks a viewer by mime type (`FilePreview.viewerFor`) and loads it through a `Loader` from `viewerSources`, a map from viewer key (`image`, `svg`, `thumbnail`, `text`, `folder`) to a QML url that a host can extend or replace. A viewer gets `pane` as its initial property, loads in `Component.onCompleted` and again on `pane.revisionChanged`, reads `pane.settledEntries`, `pane.settledViewer`, `pane.backend`, `pane.readsAllowed`, `pane.thumbnailsEnabled` and `pane.chipColor`, and stops its work and drops its content when `pane.current` turns false; it exposes `showsContent` (hides the icon), `note` (a line under the name) and `rows` (`[{id, label, value}]`, an id already shown replaces that row). Column view previews `FileViewBody.previewEntry()`: the cursor item when it is selected, otherwise the first selected one. It keeps one fixed slot right of the active column, at least `previewPaneWidth` wide, where the look-ahead column of a selected folder and the preview card of a selected file take turns; columns are `columnPaneWidth` wide whatever the depth, so moving between folders and files, or toggling `FileViewBody.previewOpen`, never moves or resizes the columns. The strip scrolls only when the active column or its slot would leave the viewport, and then by the minimum. Every folder on screen is listed once: `FileBrowserView` owns a `DirectoryPool` that keeps one `DirectoryModel` per path, `FileBrowserView.directory` is the pool's model for the current path (the object changes on navigation, `FileViewBody.directoryReplaced` fires after the body reset its selection), and column view hands the pool the paths it shows through `FileViewBody.directoryPool`, so entering a look-ahead column, going up with Left or clicking a folder in a parent column sends no request and rebuilds no column. A new column shows once its listing lands or after `skeletonDelay`, sliding in a short way, or only fading when it replaces a sibling; a column that leaves narrows and fades, and a jump to an unrelated folder replaces the strip at once. Nothing animates under reduce motion. `FilePreviewDrawer` docks the same pane beside a `FileViewBody` (`body`): set `open`, `available` (the width the body and the drawer share) and `preferredWidth` (0 means 45% of `available`), and persist the width `resized(width)` reports (0 after a double click). It previews the same item, and with several selected it adds a `DCarousel` strip of the selection in view order (`selectionInViewOrder()`) whose tiles pick the previewed item without changing the selection; the pane shows its position as `caption`. It reserves its final width at once, so the file view relayouts a single time, and slides its card in when something is selected and out `settleInterval` after the selection empties (standard curve, `expressiveFastSpatial`), releasing the width only after the slide; shrinks to `previewDrawerMinWidth`, then hides while less than `previewViewMinWidth` would remain for the files, and creates no pane while closed, empty, hidden or narrowed away. `FileBrowserView` places one when `previewDrawer` is true (default false) and forwards `previewOpen`, `previewWidth` and `previewResized`. `previewKeys` (on both) turns on the preview keys and reports them as `FileViewBody.previewKeyRequested(action, step)`: Space `toggle` (selection toggling moves to Ctrl+Space), Shift+Space and Ctrl+Shift+Space `step` ±1 through the strip, Alt+PageUp/PageDown `scroll` the preview content, Ctrl+Alt+Left/Right `resize` by `previewKeyStep` and Ctrl+Alt+0 resets the width (step 0). `FileBrowserView` turns `toggle` into `previewToggleRequested` and hands the rest to its drawer through `handleKey(action, step)`.

`DCommon/Common/LayoutCodes.js` (keyboard layout name → short code) is imported by relative path.

`DCommon/Common/WheelInput.js` classifies a QML WheelEvent by its scroll phase: `isTouchpad(wheel)` (finger source, the only one Qt Wayland gives phases), `verticalKind(wheel)` (`touchpad`, `wheel`, `highResWheel`, `none`) and `anyAxisDelta(wheel)`. Use it instead of testing `pixelDelta`, which wheels also carry from Qt 6.12. Imported by relative path.

## Consuming from an app

Add this repo as a git submodule at the app repo root, then symlink it into the quickshell config root:

```sh
git submodule add https://github.com/AvengeMedia/dank-qml-common.git dank-qml-common
ln -s ../dank-qml-common/DCommon quickshell/DCommon
```

Anything that copies the quickshell tree for packaging must dereference the symlink (`cp -rL`) - `go:embed` and most packaging flows reject symlinks.

## Standalone development

The repo root is a runnable Quickshell config with stub singletons and a widget gallery:

```sh
qs -p /path/to/dank-qml-common
```

For qmlls completion, create an empty `.qmlls.ini` at the repo root once (`touch .qmlls.ini`, gitignored) - quickshell replaces it with a generated config on the next launch, and every file in the repo gets language-server support. The stubs in `Common/` and `Services/` double as the executable contract below - if a shared widget needs a new singleton property, add it to the stub in the same change.

## Widgets

`DSlider` leaves wheel input to its enclosing flickables while any of them overflows, which forces `wheelEnabled` false. There is no per-slider opt-out. Otherwise `wheelEnabled` controls wheel adjustment. Dragging and keyboard adjustment work in either case.

`DSlider` steps with the arrow keys, `DDropdown` opens on Down, and `DDragHandle` moves its item on Up and Down. In a surface where Up and Down move focus between controls, set `DSlider.upDownKeysStep: false` (Left and Right still step), `DDropdown.downKeyOpens: false` (Alt+Down, Enter and Space still open it) and `DDragHandle.upDownKeysMove: false` (the owner handles reordering, for example on Ctrl+Up and Ctrl+Down).

`DDropdown.showLabel: false` shrinks the trigger to its swatch or icon plus the arrow, on whatever surface it sits on: no fill until hover and no outline until keyboard focus; the menu keeps `dropdownWidth` unless `popupWidth` is set. `text` still names it for screen readers.

`DBadge.maximumWidth` elides the label; `truncated` reports when it did, and `tooltipText` shows a hover tooltip, so `tooltipText: truncated ? text : null` restores the full text.

`DDetailChip` shows a `label: value` pair on the chip tier, for read-only details such as a network's frequency or a printer's state.

`DDialog` provides a title, supporting text, scrollable content and trailing actions. Use it as content inside a window, or set `embedded: false` for its scrim, elevated surface and entry motion. Handle `accepted` and `rejected`; use `acceptEnabled` and `closeEnabled` for pending actions.

`DBottomSheet` fills its parent with a scrim and a bottom-aligned, scrollable sheet. Bind `opened`, handle `dismissRequested`, and place content inside it. The handle supports dragging down to dismiss. `initialFocusItem` selects the first control; `returnFocusItem` overrides the saved opener. `dismissible: false` blocks dismissal. Use the visible viewport as its parent when the underlying content scrolls. The handle uses `bottomSheetHandleWidth` and `bottomSheetHandleHeight` (36 and 4). Its color is `onSurfaceVariant_40` (`onSurfaceVariant` at 40% opacity).

`DWindowHeader` provides floating-window titles, optional subtitles, and minimize, maximize, and close buttons. Set `controls` to the window's `FloatingWindowControls`, provide `title`, and handle `closeRequested`. The title is centered in the window and elides symmetrically so it never runs under the buttons; set `titleAlignment: Text.AlignLeft` for a left-aligned headline. Add toolbar actions as children. Use `closeEnabled` and `closeTooltipText` when closing depends on dialog state. Set `controls: null` for an embedded surface with only a close button. While `Host.ownWindowDecorations` is false the header of a native window collapses to its extra actions, or to a single `windowInset` so the top gap matches the other edges, and `FloatingWindowControls` lets the compositor decorate; with it true the controls mark the window frameless so no compositor or Qt decoration is drawn. The component owns title typography, button styling, spacing, and dragging; size the content below it from the header's height. It draws no divider: the window surface carries the header, and content sits on a raised `floatingWindowNestedSurface` pane. Every gap in the chrome is `windowInset`: the buttons sit that far from the top and trailing edges and from each other, the header's bottom padding is the same, so content that starts at the header's bottom edge and keeps `windowInset` from the other window edges is evenly spaced all around.

`DReorderList` lays out a model with variable-height delegates and emits `reordered(indices)` for persistence. Pair it with `DDragHandle`, which extends `DActionButton`: connect `started`, `moved`, `finished`, `dragCanceled`, and `moveRequested` to the list's `begin(index, position)`, `dragTo(position)`, `finish()`, `cancel()`, and `move(index, delta)`. Set `coordinateItem` to the list and bind `dragging` to `list.draggingIndex === index`. Set `flickable` for edge scrolling. Delegates can gate position transitions on `animateLayout` and implement `focusHandle(reason)` to restore focus after a move.

`DReorderGroup` coordinates transfers between lists. Set each list's `group`, `groupKey`, and `dropArea`, and set the group's `coordinateItem` to their common ancestor. Handle `transferred(sourceList, sourceIndex, targetList, targetIndex)` to persist a transfer. Bind a preview to `sourceItem` and `position`; the group manages insertion gaps and cancellation across its lists.

`DCommon/Widgets/` (`qs.DCommon.Widgets`) holds Material 3 Expressive controls (toggle, slider, buttons, button group, chips, tabs, dropdown, text fields, stepper, collapsible section, location search, refresh button, tooltip) plus `DCard` (tonal surfaces with shared content colors, focus and pressed states), `DTone` (the non-visual tone resolver behind `DCard`: set `tone` and read `surfaceColor`, `contentColor`, `accentColor`, `onAccentColor`, `mutedColor`, `chipColor`), `DListRow` (passive grouped rows with separate child controls), `DClockFace` (responsive digital and stacked time layouts with `fontFamily`, `weight` and `rounded` typography), `DClockWidget` (the configurable clock behind the DMS desktop and lock clock and the greeter clock: `cfg` picks the face and options, the host binds `now`, `locale`, `use24HourClock`, `padHours12Hour`, `dateFormat`, `fallbackFontFamily`, `accentColor` and optionally `twoToneColor`, the second tone of the accent-minutes option), `DAnalogClock` (hands, hour numbers, orbiting second dot and a date label that avoids the hands, on a `DOrganicBlob` lobed background), `DTimePicker`, `DMonthGrid` (a month calendar grid with day cells, event dots, week numbers, optional weekend tint and a `dayClicked` signal), `DMaterialShape` (M3 expressive shapes such as cookie, sunny, burst, clover, gem and diamond drawn with QtQuick.Shapes), `DLoadingIndicator` (the M3 expressive indeterminate loading indicator), `DSparkline` (a smoothed trend line with area fill for one or two series) and `DRingGauge` (a 0 to 1 arc with a track, a center content slot, `startAngle`/`spanAngle` for open arcs and `trackGap` to split the track from the value; a negative `value` hides the ring). All widgets use this module. DMS imports this module directly; the `Dank*` names left in `quickshell/Widgets/` are shims for plugins that log a deprecation warning once per type. Expressive widgets read the shape scale, state layer, spring and on-role tokens listed below.

`DSlider.startIcon` and `endIcon` follow RTL. Set `iconsClickable: true` to decrease and increase the value using the slider's keyboard step. Both actions use `sliderValueChanged` and `sliderDragFinished`. The old `leftIcon` and `rightIcon` names remain aliases.

`DSlider` handles follow the M3 tokens: 4 px wide (`sliderHandleWidth`), 2 px while pressed (`sliderHandleWidthPressed`), and as tall as the selected size prescribes (`sliderHandleHeight`, `sliderHandleHeightS/M/L/XL`).

`DSlider.centerMinimum` places `minimum` halfway along the track and fills the track up to the handle. The remaining half covers `minimum` through `maximum`; positions before the midpoint select `minimum`. For a 100–200 range, 100 is at the centre, 150 at three-quarters, and 200 at the end. RTL reverses the direction.

`DSlider.insetIcon` places an icon inside small and larger standard sliders (16 px glyph on `s`, 24 on `m` and `l`, 32 on `xl`). `trackHeight`, `handleHeight`, `trackCornerRadius` and `insetIconSize` default from `size` and can be overridden for an in-between step. `insetIconPosition` accepts `"start"` or `"end"` and follows RTL. Set `insetIconClickable` and `insetIconTooltip` for an action, and handle `insetIconClicked`. Clicking activates the icon; dragging from it adjusts the slider. `focusTargets` exposes the icon action and slider for explicit keyboard traversal. `fillTextColor` and `trackTextColor` control icon contrast on their respective track segments. Value bubbles render above clipped content.


`DSparkline.edgeExtension` extends the strokes past the end samples using their neighbouring slopes, bounded by the vertical insets. It does not add sample dots.

`DSparkline.xValues` positions samples on an explicit axis between `minimumX` and `maximumX`. Omit it for evenly spaced samples.

`DButtonGroup` uses arrows to move focus and select single choices by default. Set `arrowKeysSelect: false` to move focus without selecting; Enter, Space or a click applies the focused choice. This manual mode exposes the segments as checkable buttons instead of radio buttons.

`DButtonGroup` accepts `{ text, icon }` options. Set `iconOnly: true` for icons with text tooltips and accessible names.

`DFlickable.wheelEnabled` disables its vertical wheel handler when a surface supplies horizontal wheel navigation. Touch and mouse dragging remain available.

`DFlickable`, `DListView` and `DGridView` place their scrollbar `scrollbarGap` past the content's trailing edge. When the content fills the view, the bar moves into the nearest ancestor with room beside the view, and stops at the first `Rectangle` without room, where it overlays the view's edge instead. `showScrollBar: false` hides it for one view; `scrollbarsEnabled` hides it everywhere. Scrolling keeps working either way.

`WindowCaptureGuard.prepare()` sets `active` and waits for a rendered frame before emitting `ready`. Bind the transparent window's content and blur visibility to `!active`; hide the window and start capture on `ready`. Call `cancel()` when restoring or abandoning the capture.

`DDialog.popout` drops the header and uses compact popout spacing. `headerActions` adds buttons before the shared window controls.

`DSlider.trackGradient` paints a continuous gradient across both track segments and follows RTL. The normal handle, gap, input and disabled behavior are preserved.

`DSaturationValuePicker` edits saturation and value for a given hue. Bind its three values and handle `colorChanged(saturation, value)`. Arrow keys adjust by 1%, Shift adjusts by 10%, Home/End set saturation, and PageUp/PageDown adjust value.

`DCarousel` is the M3 multi-browse carousel: a horizontal `ListView` that fills its width with large, medium and small items, start-aligned at rest and mirrored at the end of the scroll so the last item can reach full size. Set `model`, `preferredItemWidth` (the large size it aims for, default `height`) and `smallItemWidth` (`listItemHeight`). Its delegate is a `DCarouselItem`: children fill the item at its unmasked size and the item's rounded mask (`itemRadius`, `cornerRadiusXL`) crops them around the centre as it shrinks, so content does not squash. Read `maskWidth` to hide content that no longer fits, and handle `clicked`.

`DColorButton` displays `swatchColor` with a selection check and emits `clicked`. Set `selected` to reflect the current color, and `tooltipText` to name the color instead of showing its hex value. `DColorSwatch.minPreviewAlpha: 0` displays the exact alpha over a checkerboard.

## The contract

Shared code never imports app singletons. The app injects them once at startup (`DC.Style.theme = Theme`, `DC.Style.settings = SettingsData`, `DC.I18n.backend = I18n`, `DC.Paths.backend = Paths`, `DC.Log.backend = Log`, `DC.Host.session = SessionService`, `DC.Host.cache = CacheData`, `DC.Host.files = <files backend>`, with `import qs.DCommon.Common as DC`), and `Style` reads every token through `theme?.x ?? fallback`. The gallery's `shell.qml` does the same with the stubs in `Common/` and `Services/`. Every consuming app must provide these singletons with at least the properties the library reads:

### `qs.Common` → Theme

Colors: `primary`, `primaryText`, `primaryContainer`, `primaryHover`, `primaryHoverLight`, `primaryPressed`, `primarySelected`, `secondary`, `surface`, `surfaceText`, `surfaceTextHover`, `surfaceTextMedium`, `surfaceTextSecondary`, `surfaceVariant`, `surfaceVariantText`, `surfaceVariantAlpha`, `surfaceHover`, `surfacePressed`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceTint`, `surfaceLight`, `background`, `outline`, `outlineButton`, `outlineMedium`, `outlineStrong`, `outlineHeavy`, `error`, `errorHover`, `errorSelected`, `warning`, `shadowStrong`, `buttonBg`, `buttonText`, `buttonHover`, `buttonPressed`, `floatingSurface`, `nestedSurface`, `floatingWindowSurface`, `floatingWindowNestedSurface`, `floatingWindowFieldColor`, `floatingWindowFieldBorderColor`, `floatingWindowFieldFocusedBorderColor`, `popupFieldColor`, `popupFieldBorderColor`, `popupFieldFocusedBorderColor`, `widgetBaseHoverColor`, `onPrimary`, `onSurface`, `onSurface_12`, `onSurface_38`, `contrastDark`, `contrastLight`.
 Widgets also read `tertiary`, `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainerHighest`, `surfaceBright`, `surfaceDim`, `outlineVariant`, `secondaryContainer`, `tertiaryContainer`, `onSurfaceVariant`, `onSurfaceVariant_30`, `onSurfaceVariant_40`, `onPrimaryContainer`, `onSecondaryContainer`, `onTertiaryContainer`, `onErrorContainer`, `selectedContainer` (the one selected-item fill: the theme's `secondaryContainer` when `themedSelectedContainer`, i.e. it is explicit and keeps both `onSecondaryContainer` and `surfaceText` at 4.5:1, else `surfaceContainerHigh` tinted by `selectedContainerTint` of `primary` with the same guarantee), `onSelectedContainer`, `accentOnSelectedContainer`, `accentOnPrimaryContainer`, `inverseSurface`, `inverseOnSurface`, `errorContainer`, `tonalTintAlpha`, `accents` (categorical container/glyph pairs from `Accents.derive`, read through `Style.accent(name)`).
 `primaryContainer` is the container the host paints, not the theme's raw value: `Tonal.softContainer(primary, surfaceContainer, tint)` holds the tone 16 above a dark `surfaceContainer` (floor 30) or 4 below a light one (ceiling 90), then mixes the card's own hue at that tone with the `primary` hue at chroma 48 or less. `tint` is the accent share, `Tonal.defaultTint(surfaceContainer)` gives 0.5 on dark and 1 on light. Fading toward the card instead of grey keeps the hue reading true on tinted surfaces. A theme's `softPrimaryContainer` replaces the result and `containerTint` sets the share.
 Container fills go through the semantic roles `hostSurface`, `cardSurface`, `chipSurface`, `chipSurfaceNested`: a host floats over the desktop, a card sits inside a host, a chip sits inside a card, and a nested chip sits inside a chip. The raw `surfaceContainer*` tokens stay palette-honest.

Metrics: `spacingXXS`..`spacingXL`, `fontSizeSmall`..`fontSizeXLarge`, `iconSizeSmall`/`iconSize`/`iconSizeLarge`, `cornerRadius`.
 Expressive: `fontSizeXXLarge`, the shape scale `shapeScale`, `cornerRadiusXS`..`cornerRadiusXXL`, `cornerRadiusLIncreased`, `cornerRadiusXLIncreased`, `cornerRadiusFull` (compatibility sentinel; `cornerRadiusSmall`/`cornerRadiusLarge` alias S/L), `groupedListGap`, `groupedListInnerRadius`, `groupedListOuterRadius`, `iconButtonSize`, `minimumTouchTargetSize`, `listItemHeight`, `listItemTwoLineHeight`, `avatarSize`, `sliderTrackHeight`, `sliderHandleWidth`, `sliderHandleWidthPressed`, `sliderHandleHeight`, `sliderHandleGap`, `sliderTrackHeightS/M/L/XL`, `sliderHandleHeightS/M/L/XL`, `switchTrackWidth`, `switchTrackHeight`, `switchOutlineWidth`, `switchThumbUnselected`, `switchThumbSelected`, `switchThumbPressed`, `sliderStopSize`, `sliderTickSize`, `sliderTrackMinAlpha`, `menuItemHeight`, `iconSizeMedium`, `outlineWidth`, `outlineWidthFocused`, `layerOutlineWidth`, `dividerWidth`, `windowInset`, `focusRingWidth`, `focusRingOffset`, `focusRingColor`, `scrimAlpha`, `smallBreakpoint`, `mediumBreakpoint`, `fontSizeDisplay`, `fontSizeDisplayLarge`, `buttonHeightXXS/XS/S/M`, `windowRadius`, `buttonMinWidth`, `pressScale`, `iconEnterScale`, `popupEnterScale`, `osdHeight`, `dialogMaxWidth`, `sidebarWidth`, `bottomSheetHandleWidth`, `bottomSheetHandleHeight`, `pendingOpacity`, `spinnerStrokeWidth`, `tabMinWidth`, `tabIndicatorHeight`, `tabIndicatorMinWidth`, `tabIndicatorInset`, `fieldDefaultWidth`, `fieldHeight`, `fieldHeightLarge`, `outlinedFieldLabelLineHeight`, `textFieldSpatialStiffness`, `textFieldSpatialDampingRatio`, `textFieldFastEffectsStiffness`, `textFieldSlowEffectsStiffness`, `textEditHeight`, `tooltipMaxWidth`, `tooltipDelay`, `scrollbarThickness`, `scrollbarGap`, `scrollbarHideDelay`, `menuMaxHeight`, `clockFaceSize`, `clockOuterRingRatio`, `clockInnerRingRatio`, `clockHandWidth`, `clockHandleSize`, `clockCenterSize`, `clockSwitchDelay`, `chipIconSize`, `buttonGroupExpandRatio`.

[Shapes](SHAPES.md) documents `radiusStrength`, the component baselines and the radius helpers.

`DSplitButton` supports `xs`, `s`, `m`, `l`, and `xl` sizes and `filled`, `tonal`, `outlined`, and `elevated` variants. Handle `clicked` for the main action and `menuClicked` for the menu. Set `menuOnly: true` to open the menu from either half. Bind `expanded` to the menu's visibility and use `trailingButton` as its anchor and focus return target. The gallery includes both interaction modes.

`DFab` is the M3 Expressive FAB. Set `text` for the small extended FAB or leave it empty for the icon-only FAB. `colorRole` accepts `primaryContainer` (default), `secondaryContainer`, `tertiaryContainer` and `primary`. `busy` swaps the icon for a spinner. The spec has no disabled FAB, so the container keeps its color; hide the FAB when its action is unavailable.

`DLayer` groups content for opacity effects and sizes its texture in physical pixels using the window's device pixel ratio.

Google Sans Flex is bundled under the [SIL Open Font License](DCommon/assets/fonts/google-sans-flex/OFL.txt), from [Google Fonts](https://fonts.google.com/specimen/Google+Sans+Flex).

Typography: `fontFamily`, `monoFontFamily`, `displayFontFamily`, `defaultFontFamily`, `defaultMonoFontFamily`, `defaultDisplayFontFamily`, `fontWeight`. The library bundles and registers its own fonts (Google Sans Flex, FiraCode Nerd Font, DM Serif Display, Notable, Gochi Hand, Material Symbols - `DCommon/assets/fonts/`) through the `Fonts` singleton in `qs.DCommon.Common`; apps typically bind `defaultFontFamily: Fonts.sans`, `defaultMonoFontFamily: Fonts.mono` and `defaultDisplayFontFamily: Fonts.display` rather than shipping font files of their own. `StyledText { fontToken: "display" }` resolves through `Style.fontFor(token)`: `ui`, `mono`, `display`, or a family name such as one from `Fonts.bundledFamilies`. Adding a bundled face is a font file with its license, a `FontLoader` and an entry in `Fonts.bundledFamilies`.

Animation: `shorterDuration`, `shortDuration`, `mediumDuration`, `standardEasing`, `emphasizedEasing`, `currentAnimationSpeed`, `expressiveCurves`, `expressiveDurations`. Both expressive maps carry the M3 Expressive scheme from the [motion specs](https://m3.material.io/styles/motion/overview/specs): `expressiveFastSpatial` (350ms), `expressiveDefaultSpatial` (500ms), `expressiveSlowSpatial` (650ms), `expressiveFastEffects` (150ms), `expressiveEffects` (default effects, 200ms) and `expressiveSlowEffects` (300ms). Durations scale with the app's animation speed.
 Expressive: `stateLayerHover`, `stateLayerFocus`, `stateLayerPressed`, `stateLayerDrag`, `springSpecs`, `springDampingScales`, `springMotionDisabled`, `springPreset(name, baseDuration)` returning `{stiffness, damping, mass}`, `elevationLevel1`, `elevationLevel3`.

Misc: `isLightMode`, `popupTransparency`, `floatingWindowTransparency`, `blurLayersActive`, `connectedSurfaceBlurEnabled`, `elevationEnabled`, `elevationLevel2` (`{blurPx, offsetX, offsetY, spreadPx, alpha}`), `currentAnimationBaseDuration`, `withAlpha(color, alpha)` - which must tolerate an undefined color and return transparent - and `blendAlpha(color, alpha)` with the same tolerance.

Optional (used by `ElevationShadow` when present, static fallbacks otherwise): `elevationLightDirection`, `elevationOffsetXFor()`, `elevationOffsetYFor()`, `elevationShadowColor()`, `elevationAmbient()`.

### `qs.Common` → SettingsData

Enums `AnimationSpeed`, `TextRenderType`, `TextRenderQuality`; properties `animationSpeed`, `enableRippleEffects`, `popoutElevationEnabled`, `scrollbarsEnabled`, `textRenderType`, `textRenderQuality`.
 Expressive motion: `reduceMotion`, `springBounce`. Blur border (FileBrowser): `blurBorderEnabled`, `blurBorderOpacity`, `blurBorderColor`, `blurBorderCustomColor`.

Lock surfaces: `lockScreenContentColor`, `lockScreenScrimAlpha`, `lockScreenBlur`, `lockScreenBlurMax`, `screenOffColor`.

Power menu (Session components): `powerActionConfirm`, `powerActionHoldDuration`, `powerMenuActions`, `powerMenuDefaultAction`, `powerMenuGridLayout`.

### `qs.Common` → Anims, Paths, CacheData, I18n

- Anims: `durShort`, `standard`, `emphasized` (bezier arrays)
- Paths: `xdgCache`, `imagecache` (urls), `strip(url)`, `stringify(url)`, `resolveIconPath(iconName)` (return `""` when the app has no icon-theme resolution; `FileIcon` falls back to a Material Symbol), `copyPathToClipboard(path)`; the app must create `imagecache`. The stub uses `Quickshell.clipboardText`
- CacheData: `fileBrowserSettings` (var, one record per picker `bucket`: `viewMode sortKey sortDesc gridZoom listZoom showSidebar showHidden lastPath`; read and written only through `FileBrowserSettings`), `saveCache()`
- I18n: `tr(term, context)`, `isRtl`

### `Host.files`

The file browser never touches the disk. Every listing, stat, thumbnail and change goes through the backend the app injects as `DC.Host.files`, which is expected to forward to the shared `files.*` IPC family (`dankgo/files`) on the app's own daemon. `null` or `connected: false` renders an "unavailable" placeholder instead of failing. The stub `Services/FilesBackend.qml` implements the whole surface over an in-memory tree.

Callbacks receive the method's result object, or `{error, code}` with a stable code (`ENOENT EACCES ENOTDIR EINVAL EEXIST EBUSY EIO NOTSUPPORTED SANDBOXED`, plus `UNAVAILABLE` from the library itself). Paths are absolute strings, never URIs.

| member | shape |
| --- | --- |
| `connected` | bool |
| `userDirs` | `[{key, name, path, iconName}]`, home first (`files.userDirs`) |
| `capabilities` | `{mkdir, rename, trash, search}` bools; a missing or false key hides the action |
| `watch(path, options, cb)` | `files.watch`. options `{includeHidden, filters, sortKey, sortDesc, dirsFirst, limit}`; result `{watchId, seq, entries, total, hidden, cursor, watching, pollOnFocus}`, `hidden` counting the hidden entries the listing leaves out |
| `page(watchId, options, cb)` | `files.list` with `watchId`, same options plus `cursor`; also changes the watch's sort, hidden and filters |
| `unwatch(watchId)` | `files.unwatch`, no callback |
| `stat(path, cb)` | `files.stat`, `{entry}` |
| `count(paths, includeHidden, cb)` | `files.count`, `{counts: {path: {count, capped, code}}}` |
| `thumbnails(paths, size, watchId, cb)` | `files.thumbnail`, `{results: [{path, thumbnail}]}`; late results arrive as `thumbnails` events |
| `mkdir(path, cb)` | `files.mkdir`, `{path, entry}` |
| `rename(path, name, cb)` | `files.rename`, `{path}` |
| `trash(paths, cb)` | `files.trash`, `{trashed, failed: [{path, code, error}]}` |
| `watchEvent(data)` | signal carrying every event of every watch the backend opened: `{watchId, kind, seq, added, addedAt, changed, removed, thumbnails, hidden}`, `kind` one of `batch resync gone thumbnails`; a `batch` carries `hidden` only when that count changed |
| `search(root, query, options, cb)` | optional, `search.start`. options `{includeHidden, crossDevice, types, modifiedAfterMs, minSize, maxSize, limit}`; result `{searchId, topic, limit}`. `SearchModel` hides the actions when it is missing |
| `cancelSearch(searchId)` | optional, `search.cancel`, no callback |
| `searchEvent(data)` | signal carrying `{searchId, kind, entries, count, truncated, cancelled, unreadable}` with `kind` `results` (a batch to append) or `done` |
| `list(path, options, cb)` | optional, `files.list` without a watch, same options; the path bar completes folder names from it |
| `resolveLocation(text, cwd, cb)` | optional, `location.resolve`. Turns what was typed in the path bar into `{location: {kind, path, select, uri, password}}`, `kind` one of `folder` (navigate, or reveal `select`), `remote` and `servers` (handed to the host); errors carry `ENOENT`, `EACCES`, `EOTHERHOME` (`~name`), `EINVAL` or `NOTSUPPORTED`. Without it the path bar only takes absolute paths and `~` |
| `preview(path, maxBytes, cb)` | optional, `files.preview`, `{text, binary, truncated, size, lines}`; the preview's text viewer reads up to `FileBrowserMetrics.previewBytes` |
| `imageSize(path, cb)` | optional, `files.imageSize`, `{width, height, format}` read from the image header; the preview shows it as Dimensions |
| `scanSize(paths, cb)` | optional, `files.size`, `{scanId}`; totals arrive on `sizeEvent` |
| `cancelScan(scanId)` | optional, `files.sizeCancel`, no callback |
| `sizeEvent(data)` | optional signal carrying `{scanId, bytes, files, dirs, done, cancelled, code}`; without it and `scanSize` a folder preview shows its item count only |

Entries are the `files.*` entry schema with every key present (`name path isDir isSymlink symlinkTarget symlinkBroken size mtimeMs ctimeMs atimeMs mode owner group hidden isExecutable extension mime iconName thumbnail thumbnailable unreadable displayName untrusted`). `filters` are case-insensitive globs over file names; directories always pass and `*`/`*.*` mean no filter. Watch batches are applied in order without sorting: removals by name, changes in place, then each added entry at its `addedAt`; a `seq` gap re-pages.

### `qs.Services` → Log

`scoped(module)` returning `{debug, info, warn, error}`.

### `qs.Services` → SessionService

Used by `LockPowerMenu`: `hibernateSupported` plus `logout()`, `suspend()`, `hibernate()`, `reboot()`, `poweroff()`. Apps where an action makes no sense (logout in a greeter) provide it as a no-op.

## Translations

Widget strings are owned here, not by the consuming apps. `translations/extract_translations.py` scrapes `I18n.tr()` from `DCommon/` into `translations/en.json`; the DMS POEditor project is the source of truth for translating those terms, and its sync writes the per-locale exports into `DCommon/translations/poexports/`. Because that directory lives inside `DCommon/`, translations ship to every consumer with the submodule pointer like any other file.

Consuming apps keep their own POEditor projects app-only (their extractors must not descend into `DCommon/`) and merge both sources at runtime in their `I18n` singleton - app terms win on collision.

## Making changes

Run `node tests/run.mjs` for the shape, foreground and QML widget regressions. Requires Node.js and Quickshell with its Qt QML modules. The widget tests run offscreen, two at a time, with separate Quickshell processes and temporary settings. `prek run common-tests --all-files` runs the same suite through the repository hook; GitHub Actions runs it on pushes and pull requests.

The submodule is a real worktree; edit it in place inside whichever app you are working on and the running app picks changes up live. Land the library PR first, then bump the pointer in the app (`make update-common` keeps the submodule and nix flake input in lockstep; app CI re-syncs flake.lock automatically if they drift). If a change reads a new app-singleton property, add it to the root stubs and the contract above in the same PR; the gallery won't run without it. Other consumers upgrade whenever they bump the pointer - no lockstep.

## Notes

- `Common/Proc.qml` exposes `dmsBin` (`DMS_EXECUTABLE` env override) as a DMS convenience; it is inert elsewhere.
- Log stays app-owned so each app keeps its own env-var prefix (`DMS_LOG_LEVEL`, `DANKCAL_LOG_LEVEL`, ...).

Launcher metrics: `launcherTileSize`, `launcherImageRatio`, `launcherMaxVisibleRows`, `launcherWidthMicro`, `launcherWidthDefault`, `launcherWidthWide`, `launcherWidthLarge`, `launcherHeightDefault`, `launcherScreenMargin`. Rows use a uniform `listItemHeight`, `avatarSize` and the grouped list tokens. Modal dimming uses `scrimColor` with `scrimAlpha`.

At `radiusStrength: 50`, the Expressive shape scale is 4, 8, 12, 16, 20, 28, 32 and 48 for XS, S, M, L, LIncreased, XL, XLIncreased and XXL. Zero removes configurable rounding. See [Shapes](SHAPES.md) for component baselines and legacy compatibility.

`Style.foregroundColor(baseColor, floatingWindow)` applies the host's foreground toggle and opacity to a raw surface color. Cards, list items, fields and button groups use it for their background fills. Pass raw colors to field `backgroundColor`; any alpha in that color multiplies the foreground opacity. Text, icons and interaction states retain their own opacity.

Mark a window's content root with `isFloatingWindowSurface: true` to use floating window preferences. A nested root with `isFloatingWindowSurface: false` uses global preferences. `Style.isFloatingWindow(item)` reads the nearest marker and supports the older `disablePopupTransparency: true` marker. Outer window and menu surfaces use window opacity separately from foreground fills.

`DMaterialShape` uses normalized cubic paths exported from [AndroidX MaterialShapes](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MaterialShapes.kt) with AndroidX graphics-shapes 1.0.1. `shape` selects a lower-camel-case catalog name, including `cookie4`, `cookie6`, `cookie7`, `cookie9`, `cookie12`, `triangle`, `sunny`, `verySunny`, `flower`, `arch` and `heart`. `rotationScale` gives a scale that keeps the rotated outline inside its original inscribed circle. `rotationScaleForAspectRatio(width / height)` accounts for stretched artwork; multiply the available circle diameter by that scale for the artwork height, then by the aspect ratio for its width. `color` sets the fill. `fillProgress` (0–1) fills the shape from the bottom, with `trackColor` above the fill. Shapes become square when the theme radius is zero; set `respectThemeShape: false` for illustrations that must retain their geometry. See `MaterialShapes.NOTICE` beside the path data for licensing.

`DLoadingIndicator` follows the AndroidX [LoadingIndicator](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/LoadingIndicator.kt): a 48 container with a 38 active shape, the soft burst, 9-sided cookie, pentagon, pill, sunny, 4-sided cookie and oval sequence, one morph every 650 ms on a 0.6 damping, 200 stiffness spring with a quarter turn per morph, and a full turn every 4666 ms. Each shape is sampled into a radius-around-center profile, and a fragment shader interpolates two profiles and antialiases the edge analytically. This approximates the AndroidX feature-matched morph. `size` sets the container, `color` the fill (primary by default), and `running` defaults to `visible`.

`DNavigationBar` accepts `model` entries with `icon` and `text`, `currentIndex`, and `orientation` (`Qt.Horizontal` or `Qt.Vertical`). It emits `activated(index)` and scrolls overflowing destinations. Horizontal destinations share the width evenly by default; `evenlySpaced: false` creates a compact centered group. Vertical destinations are always a centered group. With `editable: true`, the selected icon reveals a pencil on hover and emits `editRequested(index)`; F2 also requests editing. Labels remain visible below icons.

Navigation tokens: `navigationHeight` (64), `navigationRailWidth` (96), `navigationItemMinWidth` (80), `navigationIndicatorWidth` (56), `navigationIndicatorHeight` (32), and `navigationVerticalPadding` (6). Shape uses `fullRadius`; strength 50 is the Material baseline.
