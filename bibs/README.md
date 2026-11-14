# bibs/

BibTeX references for the bundled spectral-sensitivity sources (the `source`
column of `species_sensitivities`) and the key methods luxR implements.

- **`*.bib` files here are tracked in git** — they provide citation provenance
  and won't be lost.
- **Copyrighted source texts (PDF / EPUB) are git-ignored** (`bibs/*.pdf`,
  `bibs/*.epub`, …) and must never be committed.
- The whole folder is excluded from the package build (`.Rbuildignore`), so
  nothing here ships in the installed package.

Drop a `.bib` file in here (e.g. `robinson_1993.bib`) and it will be tracked.

**`inst/REFERENCES.bib` is the canonical package bibliography.** Rdpack reads
it for `\insertRef{key}{luxR}` in the help pages (e.g. `?species_sensitivities`),
and `data-raw/` provenance files cite its keys. It holds more entries than this
folder, so never regenerate it from `bibs/` (`cat bibs/*.bib > ...` would delete
the others). To add a source, check its key is not already present, append the
entry, and re-document:

```sh
grep -n "@[a-z]*{newKey2024," inst/REFERENCES.bib   # must print nothing
cat bibs/new_2024.bib >> inst/REFERENCES.bib
```

To change an existing entry, edit it in both places.
