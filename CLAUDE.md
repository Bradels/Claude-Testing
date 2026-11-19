# Notes for Claude

## Standing rules

- **Photos never go on the site.** Any photo the user sends (food, wrappers, receipts, gym, anything) is saved to `_photos/` in the repo as `YYYY-MM-DD-<short-description>.jpg`, with EXIF/metadata stripped. Never put a photo in `images/`, embed it in a page, link to it from a page, or reference it in `data/*.json`.
  - `_photos/` is kept out of GitHub Pages two ways: Jekyll skips folders that start with `_`, and `.github/workflows/deploy-pages.yml` deletes `_photos` before uploading the site. Keep both in place.

## Fuel & Lift Log

- Page: `log.html`. Data: `data/log.json` (days with food items and notes, `weighIns`, `workouts`, `targets`). Add new entries to the JSON; the page renders everything from it.
- Energy and macros are estimates: use label values when a wrapper shows them, and say which items are estimates.
- Weight is in kg, energy in both kJ and kcal (Australian labels use kJ).

## Deploying

- GitHub Pages deploys on pushes to `claude/explore-features-Vbvih` and `main`.
