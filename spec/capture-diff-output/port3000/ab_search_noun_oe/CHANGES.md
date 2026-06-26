# ab_search_noun_oe

**STATUS: FINISHED**

_Signed off. Remaining sidebar "Current Filters" chip styling (ORIG solid green pill vs
port bordered chip + boxed `x` + `>` caret) accepted as a BL9 constraint-chip change._

## Fix 5: Entry panel double padding (COMMON / results)

**Problem:** Inside each result `<article>`, the gray `.definition-block` (Sense/Definition
box) stopped short of the white card edges. ORIG had no padding on `.entry-panel.panel`;
port's `.entry-panel.panel { padding: 1em }` (19px) inset the inner blocks, which already
carry their own padding -- double-padding the gray block and the title.

**Fix:** Set `.entry-panel.panel { padding: 0 }` in main.scss. The inner `.definition-block`
(own padding) and title (`.index_title` `padding: 0 1em`) supply the spacing, so the gray
block now spans the full card width like ORIG.

**File:** `app/assets/stylesheets/main.scss`

**Note (COMMON):** Applies to any search-results page.

---

## Fix 4: Result heading font size (COMMON / results)

**Problem:** Result entry headings (headword + pos, e.g. "ab n.") rendered far larger
than ORIG. BL9 dropped the small base `.index_title.document-title-heading` used to
have, so it inherited the full body size; the headword (`1.75em`) and pos (`1.5em`) are
sized relative to that base, so both scaled up ~35% (headword 33px vs ORIG 24.5px).

**Fix:** Set `.index_title.document-title-heading { font-size: 0.75em }` in main.scss.
Relative unit (not a fixed px) so the title block stays proportional and scales with the
user's browser font-size on every device. Headword lands ~24.9px (ORIG 24.5px).

**File:** `app/assets/stylesheets/main.scss`

**Note (COMMON):** Applies to any search-results page.

---

## Fix 3: Result entry spacing / padding (COMMON / results)

**Problem:** Each result `<article>` was much taller and over-padded vs ORIG. BL9 sets
`--bl-results-document-margin-top` / `--bl-results-document-padding-top: 2em` (38px at this
font size) on `.documents-list .document`; ORIG used a tight 9px top margin + padding.

**Fix:** Overrode the two BL9 theming custom-properties to `0.5rem` in the `.documents-list`
block in main.scss. Uses BL9's intended extension point, so the flex layout + dotted
border-bottom stay intact.

**File:** `app/assets/stylesheets/main.scss`

**DOM note:** Port wraps each entry in `<article>` + `.document-main-section` (BL9 upgrade)
vs ORIG's `<div class="document">`. Warranted upgrade -- kept as-is, fixed purely via CSS.

**Note (COMMON):** Applies to any search-results page.

---

## Fix 2: "Current Filters" container padding (COMMON)

**Problem:** `#sidebar #appliedParams` had no padding at desktop widths. Blacklight 9's
`.constraints-container { display: flex }` overrides Bootstrap 3's `.well` padding, leaving
"Current Filters" heading and "Start Over" link flush against the box edge.

**Fix:** Added `padding: 16px 19px` to the `@media (min-width: 768px)` override block for
`#sidebar #appliedParams` in `app/assets/stylesheets/dromedary.scss`.

**File:** `app/assets/stylesheets/dromedary.scss`

**Note (COMMON):** Applies to any page with the sidebar Current Filters box.

---

## Fix 1: Sidebar "Current Filters" box — desktop styling (COMMON)

**Problem:** `#sidebar #appliedParams` used mobile-only styles at all viewport sizes:
- Grey background (`#e5e5e5`) instead of near-white (`#fafafa`)
- Solid green chips (`#05a657`) instead of outlined light green (`#e2f4eb` bg, `#044e2a` text)
- "Current Filters" heading was 14px, not bold
- "Start Over" rendered as grey button instead of plain underlined link

**Fix:** Added `@media (min-width: 768px)` block in `dromedary.scss` that overrides
the base mobile styles to match orig's desktop CSS (orig lines 3500–3511):
- Container: `background-color: #fafafa; border: 1px solid #ddd; margin-top: 0; margin-bottom: 2px`
- Heading: `font-size: 1.15em; font-weight: 600; padding-bottom: 0.5em`
- Chips: `background-color: #e2f4eb; color: #044e2a; border: 1px solid #057c42; display: inline; white-space: normal; max-width: 100%`
- Start Over: plain link (`background: transparent; border: 0; color: #333; text-decoration: underline; font-size: 0.85em`)

**File:** `app/assets/stylesheets/dromedary.scss`

**Note (COMMON):** This fix applies to any page that shows the sidebar Current Filters box
(multi-facet search results). Already applied — do not re-apply on other pages.

**Approved differences (BL9 template changes, not CSS-fixable):**
- `>` separator between filter name and value (orig used glyphicon `›`)
- Remove button renders as separate `btn-outline-secondary` pill (orig integrated it)
