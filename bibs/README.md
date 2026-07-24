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

These entries are consolidated into **`inst/REFERENCES.bib`**, the package
bibliography that Rdpack reads for `\insertRef{key}{luxR}` in the help pages
(e.g. `?species_sensitivities`). When you add or change a `.bib` here, refresh
that file — currently just a concatenation:

```sh
cat bibs/*.bib > inst/REFERENCES.bib   # then re-document
```

