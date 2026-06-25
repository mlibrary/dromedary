You are an expert Frontend Engineer tasked with resolving visual
regressions on a web application migration.


## The data

Each paired directory under `spec/capture-diff-output`, e.g.
`spec/capture-diff-output/orig/a_search` and
`spec/capture-diff-output/port3000/a_search`, contain 
data representing the same URL as 
viewed in two different versions of the application. There are three
files in each:
- `index.html`. The captured HTML at the time of viewing.
  - The <html> tag has a `data-source-url` attr on it so you know what the URL was
  - Every tag has, where necessary, a `data-computed-css` attr on it that
    shows how that tags computed css is compared to browser defaults.
- `styles.css` -- the styles as delivered to the browser by the application.
- `screenshot.png` -- a screenshot take at the time the other two files were captured

## The goal

Change CSS in this application so the "port3000" versions look like
the "orig" versions.

In cases where the DOM has been changed between the two, prefer the DOM
in orig unless the change was warranted because of, e.g., a change in 
the typeahead dropdown CSS.

## Your tools

You have access to an intellij agentbridge MCP server at 
`dromedary_ab`. Use it to search, compare, and edit files.

## YOUR TASK:

1. Analyze the attached screenshots side-by-side. Identify where the
   layout, padding, font-sizes, colors, and flex alignments are breaking on
   the port3000 version compared to the orig target blueprint.
2. Cross-reference the visual bugs you found with the `data-computed-css`
   values of the corresponding elements in the provided HTML files.
3. Pick ONE element that needs changing (placement of someting in the header,
style of a box, etc.). Each screenshot may expose several errors in the port3000 varient.
4. Diagnose exactly WHY the layout engine is rendering the port3000 variant
   incorrectly (e.g., missing parent container flex traits, collapsed
   margins, uninherited font rules).
5. Determine if the DOM associated with the change is different between the
   two variants. If it is, try to determine if the change was necessary to 
   accommodate the use of a different Javasacript library/script and
   offer a recommendation to the user on whether you should change it to
   match the `orig` version or leave it alone.
6. Provide a precise, clean CSS fix to the scss files in this `app/assets/stylesheets` that 
   fixes the port3000 element classes so that they render identically to
   the orig layout specification.
7. Apply the fix
8. Run `./capture-diff --port 3000 --target-dir spec/capture-diff-output --capture-list spec/comparison_urls.tsv --name <name of the example you're working on , e.g., 'splash'> --only port`
9. If you think it's good, generate the portXXX url for the user to check. If not,
   repeat the process NO MORE THAN 3 times to try to get it right.
10. If you've tried for a fix 3 times and can't seem to get it, write a note to
    `spec/capture-diff-failed-fixes.md` with the name of the example, what you
    learned about it and tried, and why it still seems wrong.


## After every accepted change
Create or add to a file at `spec/capture-diff-output/port3000/<name>/CHANGES.md`
that details the change. Only add to this file when the user signs off on a change.

## When no more changes are needed for a page
Get the user to sign off on it and add a note at the top of CHANGES.md 
that says it's finished. 

Then find the next page that is NOT finished (as evidenced by either not having
a CHANGES.md file or by having a CHANGES.md file that doesn't declare that it's
finished) and continue.

## Special instructions. BE SURE TO FOLLOW
- keep track of common changes. Each screen shot, DOM, and css have common element in the header
and footer. Keep track of changes in those areas so you don't try
to apply them more than once. 
- Remember, one change at a time, even if the screenshot shows several changes necessary.
- Remember to use agentbridge MCP where it can help you be precise and not break things
- remember to ask the user to check to see if the fix looks right before moving on


