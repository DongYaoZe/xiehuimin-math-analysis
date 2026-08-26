from __future__ import annotations

import argparse
import csv
import hashlib
from pathlib import Path

import pymupdf as fitz

SOURCES = {
    "jia-yi-full": "谢惠民-数学分析习题课讲义答案 (甲乙).pdf",
    "xu-shun-upper": "谢惠民上册答案.pdf",
    "jia-yi-lower": "谢惠民下册答案.pdf",
    "jia-yi-short": "谢惠民 - 数学分析习题课讲义 下册答案.pdf",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source-dir", required=True, type=Path)
    ap.add_argument("--output", default=Path("answer-pages"), type=Path)
    ap.add_argument("--manifest", default=Path("ANSWER_PAGE_MANIFEST.csv"), type=Path)
    ap.add_argument("--width", default=1450, type=int)
    ap.add_argument("--quality", default=90, type=int)
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    rows: list[dict[str, object]] = []

    for source_id, filename in SOURCES.items():
        pdf = args.source_dir / filename
        if not pdf.exists():
            raise FileNotFoundError(pdf)
        outdir = args.output / source_id
        outdir.mkdir(parents=True, exist_ok=True)
        doc = fitz.open(pdf)
        for index, page in enumerate(doc):
            physical_page = index + 1
            target = outdir / f"page-{physical_page:04d}.jpg"
            scale = args.width / max(page.rect.width, 1)
            pix = page.get_pixmap(
                matrix=fitz.Matrix(scale, scale),
                colorspace=fitz.csGRAY,
                alpha=False,
            )
            data = pix.tobytes("jpg", jpg_quality=args.quality)
            target.write_bytes(data)
            rows.append(
                {
                    "source_id": source_id,
                    "source_pdf": filename,
                    "physical_page": physical_page,
                    "image": target.as_posix(),
                    "width": pix.width,
                    "height": pix.height,
                    "sha256": sha256(data),
                }
            )
        doc.close()
        print(f"{source_id}: {len(list(outdir.glob('page-*.jpg')))} pages")

    with args.manifest.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f"images={len(rows)} manifest={args.manifest}")


if __name__ == "__main__":
    main()
