# Source/page manifest

The full-page scans live locally under `source-pages/` and are intentionally ignored by Git. They are direct extractions of the page JPEGs embedded in the authoritative PDFs whenever possible; only pages without a usable full-page JPEG are rendered as a fallback.

Run:

```powershell
python scripts/extract_source_pages.py --source-dir "<folder containing the two PDFs>" --output source-pages --manifest PAGE_MANIFEST.csv
```

Expected result:

- upper: 443 images, `page-0001.jpg` … `page-0443.jpg`
- lower: 421 images, `page-0001.jpg` … `page-0421.jpg`
- total: 864 images

Printed-page mapping:

- upper: physical page 18 = printed page 1, so printed page = physical page − 17 for body/back matter
- lower: physical page 13 = printed page 1, so printed page = physical page − 12 for body/back matter
