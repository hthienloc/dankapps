# Gallery Thumbnail Layouts

## Problem Statement

How might DankView let people choose how they browse portrait and landscape photos while preserving the familiar layout as the default?

## Recommended Direction

Add a Gallery setting with three thumbnail layouts: the current square crop (`Crop`), showing the complete image inside an even square tile (`Fit`), and a column-balanced masonry layout (`Masonry`) that preserves the full image. Keep `Crop` as the default so existing behavior remains unchanged. In `Fit`, use the theme surface as the background for any unused space.

`Crop` and `Fit` retain the existing even grid geometry. `Masonry` balances images across columns within each date group; tile height follows image aspect ratio, with a bounded ratio for extreme panoramas and portraits.

## Key Assumptions to Validate

- [ ] Users find it easier to recognize portrait and landscape photos in `Fit` or `Masonry`; compare all modes on the same mixed-orientation library.
- [ ] The unused space around fitted images looks intentional with the theme surface background.
- [ ] Users value seeing the full image enough to choose `Fit` or `Masonry` despite uneven tile heights in Masonry.

## MVP Scope

- Add a persistent Gallery preference using a three-option button group: `Crop`, `Fit`, and `Masonry`.
- Preserve `Crop` as the default.
- Preserve the full image in `Fit` and `Masonry`.
- Keep tile size, spacing, ordering, and date grouping unchanged in `Crop` and `Fit`.
- Balance masonry columns within each date group; reuse the layout in Trash.
- Verify all modes with a mixed-orientation collection and retain compatibility with existing saved Crop/Fit preferences.

## Not Doing (and Why)

- Album-card and recent-carousel preview layouts — separate surfaces that can be revisited after the main Gallery mode is evaluated.
- Additional thumbnail layouts or per-album overrides — avoid expanding scope before the basic choice is validated.

## Open Questions

- Does the theme surface provide enough contrast around fitted images, or should the tile background be configurable?
