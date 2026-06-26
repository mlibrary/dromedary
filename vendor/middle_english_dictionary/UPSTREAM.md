# Upstream provenance: middle_english_dictionary

- Source: https://github.com/mlibrary/middle_english_dictionary
- Tag: `v1.9.1`
- Commit: `075d8c4ef6332de8091e946881414a0105ca2e46`
- Copied at: `2026-06-18`

## Copy commands

```sh
SRC=/Users/dueberb/devel/mlibrary/middle_english_dictionary
cp "$SRC/lib/middle_english_dictionary.rb" lib/middle_english_dictionary.rb
rsync -a "$SRC/lib/middle_english_dictionary/" lib/middle_english_dictionary/
rsync -a "$SRC/spec/" spec/vendor/middle_english_dictionary/
cp "$SRC/README.md" vendor/middle_english_dictionary/README.md
cp "$SRC/CHANGELOG.md" vendor/middle_english_dictionary/CHANGELOG.md
cp "$SRC/NOTES.md" vendor/middle_english_dictionary/NOTES.md
cp "$SRC/middle_english_dictionary.gemspec" vendor/middle_english_dictionary/middle_english_dictionary.gemspec
```

## Local deviations

- Upstream root support files were not copied into dromedary root: `Gemfile`, `Gemfile.lock`, `Rakefile`, `Dockerfile`, `docker-compose.yml`, `.github/`, `bin/`, `.rspec`, `.irbrc`, `.gitignore`.
- Upstream specs were vendored under `spec/vendor/middle_english_dictionary/` rather than dromedary root `spec/`.
