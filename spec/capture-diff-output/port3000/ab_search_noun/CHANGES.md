# ab_search_noun

**STATUS: FINISHED** — All fixes are COMMON changes already applied via a_search.
Remaining difference is native BS5 select dropdown caret style.

## Applied COMMON fixes (from a_search)

1. Fix "Limit your search" facets heading (COMMON / facets)
2. Recompose the pagination/sort/per-page toolbar + constraint chip (COMMON)
   - Note: ORIG showed facet constraints in sidebar "Current Filters" box;
     PORT3000 shows them as inline chips in toolbar (approved behavior change)
3. Re-skin the facet field heading + collapse caret (COMMON / facets)
4. Hide native browser search clear button (COMMON / UX -- REVIEW)

See `a_search/CHANGES.md` for full details on each fix.
