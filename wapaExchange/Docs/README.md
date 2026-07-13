# Docs

These markdown files are the source of the docs site published from `main`.

Preview locally:

```bash
pip install mkdocs-material
mkdocs serve       # http://127.0.0.1:8000
```

The GitHub Actions workflow `docs-deploy.yml` publishes to GitHub Pages on every push to `main` that touches `wapaExchange/Docs/**` or `mkdocs.yml`.

## Structure

- `index.md` — landing page for the docs site (nav card grid).
- `01_PRD.md` through `07_Partner_Outreach.md` — the actual documents, linked from `mkdocs.yml`.
- Everything renders with MkDocs Material extensions: admonitions, tabbed code blocks, task lists, permalinked headers.
