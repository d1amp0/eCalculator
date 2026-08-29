# eCalculator v4 calculator implementation plan

## Existing behaviour

- Subject marks are rendered in a fixed four-column grid.
- Every mark owns mutable score/coefficient totals and opens a large dialog.
- Edit and exclude operations first calculate a preview, then require a second
  confirmation. Added marks use a separate dialog and separate mutable list.
- The original eSchool marks are passed into the page, while simulated totals
  are stored independently in widget state.

## UX problems

- The original and predicted averages are not visually separated.
- Add, edit, and exclude require more steps than the underlying action needs.
- Weight is visually detached from the mark and scenario changes are hard to
  scan or undo.
- Fixed sizes and a `DataTable` make narrow screens and long subject names
  awkward.

## Component structure

- `MarkPage`: result, responsive mark wrap, and current-scenario summary.
- `MarkButton`: compact mark chip with explicit new/edited/excluded states.
- Bottom sheets: quick mark value, sign, and coefficient input.
- `StudentDataSource`: common boundary for eSchool and deterministic demo data.

## State model

`CalculatorScenario` keeps source marks immutable and stores only temporary
add/edit/exclude operations. Its derived marks and averages are recalculated by
the tested domain calculator after every operation. Reset clears only scenario
operations and never reloads eSchool data.
