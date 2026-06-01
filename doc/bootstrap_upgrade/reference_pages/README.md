# Reference Pages Index

These pages were captured from the live production system at `quod.lib.umich.edu` on 2026-06-01.
They serve as visual/structural reference for the Bootstrap 5 upgrade.

## Pages

| # | File | Page Type | URL |
|---|------|-----------|-----|
| 1 | `01-splash-page.md` | Splash/Home | `https://quod.lib.umich.edu/m/middle-english-dictionary/` |
| 2 | `02-dictionary-home.md` | Dictionary landing | `https://quod.lib.umich.edu/m/middle-english-dictionary/dictionary` |
| 3 | `03-dictionary-search-results.md` | Dictionary search | `https://quod.lib.umich.edu/m/middle-english-dictionary/dictionary?utf8=%E2%9C%93&search_field=hnf&q=wymmen` |
| 4 | `04-dictionary-show.md` | Dictionary entry | `https://quod.lib.umich.edu/m/middle-english-dictionary/dictionary/MED52917` |
| 5 | `05-bibliography-landing.md` | Bibliography landing | `https://quod.lib.umich.edu/m/middle-english-dictionary/bibliography` |
| 6 | `06-bibliography-search-results.md` | Bibliography search | `https://quod.lib.umich.edu/m/middle-english-dictionary/bibliography?utf8=%E2%9C%93&search_field=bib_keyword&q=women` |
| 7 | `07-bibliography-show.md` | Bibliography entry | `https://quod.lib.umich.edu/m/middle-english-dictionary/bibliography/BIB628` |
| 8 | `08-quotations-landing.md` | Quotations landing | `https://quod.lib.umich.edu/m/middle-english-dictionary/quotations` |
| 9 | `09-quotations-search-results.md` | Quotations search | `https://quod.lib.umich.edu/m/middle-english-dictionary/quotations?utf8=%E2%9C%93&search_field=quote_everything&q=women` |

## Common Elements Across All Pages

### Navigation Bar
- University of Michigan branding (SVG logo)
- "Middle English Compendium" title
- Horizontal nav: Dictionary | Bibliography | Quotations

### Keyboard Dropdown (Special Characters)
Present on ALL pages with search forms (all except splash):
- SVG keyboard icon: `keyboard-grey-*.svg`
- Dropdown with 4 characters:
  - `Þ þ` (thorn)
  - `Ð ð` (eth)
  - `Ʒ ʒ` (yogh)
  - `Æ æ` (ash)
- Each is an anchor with `href="#"` — JavaScript inserts character into active search field

### Search Form Variations
| Page Type | Search Fields | Has Keyboard |
|-----------|--------------|--------------|
| Dictionary home/results | Entire entry, Headword (alt), Headword (preferred), Definition, Etymology, Quotes, Modern English | Yes |
| Bibliography home/results | Entire entry, Author/Title, External References, LALME/LAEME Manuscripts | Yes |
| Quotations home/results | Quotation including citation, Quotation text only | Yes |
| Splash page | No search form | No |

### Footer (all pages)
- Middle English Compendium links (Dictionary, Bibliography, Corpus [external])
- Help and information (Search Help, About the MEC)
- Contact Us (Qualtrics form + email)
- Copyright notice
- "Data last refreshed 2026-01-31 07:33:00 -0500"
