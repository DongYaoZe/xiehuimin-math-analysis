from __future__ import annotations
import argparse, csv, hashlib
from pathlib import Path
import fitz  # PyMuPDF

SOURCES = {
    'upper': '谢惠民(2018) - 数学分析习题课讲义(上册)[第2版](1).pdf',
    'lower': '谢惠民(2019) - 数学分析习题课讲义(下册)[第2版].pdf',
}
OFFSETS = {'upper': 17, 'lower': 12}

def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()

def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument('--source-dir', required=True, type=Path)
    ap.add_argument('--output', default=Path('source-pages'), type=Path)
    ap.add_argument('--manifest', default=Path('PAGE_MANIFEST.csv'), type=Path)
    args=ap.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    rows=[]
    for volume, filename in SOURCES.items():
        pdf=args.source_dir/filename
        if not pdf.exists():
            raise FileNotFoundError(pdf)
        outdir=args.output/volume
        outdir.mkdir(parents=True, exist_ok=True)
        doc=fitz.open(pdf)
        for i,page in enumerate(doc):
            pno=i+1
            target=outdir/f'page-{pno:04d}.jpg'
            method='rendered-fallback'
            width=height=0
            data=None
            imgs=page.get_images(full=True)
            if len(imgs)==1:
                xref=imgs[0][0]
                rects=page.get_image_rects(xref)
                info=doc.extract_image(xref)
                if info.get('ext') in {'jpeg','jpg'} and rects:
                    r=rects[0]
                    coverage=(r.width*r.height)/(page.rect.width*page.rect.height)
                    if coverage>0.90:
                        data=info['image']; width=info['width']; height=info['height']; method='embedded-jpeg'
            if data is None:
                # Keep fallback close to the native scan width; this is source recovery, not enhancement.
                scale=1200/max(page.rect.width,1)
                pix=page.get_pixmap(matrix=fitz.Matrix(scale,scale), colorspace=fitz.csGRAY, alpha=False)
                data=pix.tobytes('jpg', jpg_quality=95); width=pix.width; height=pix.height
            target.write_bytes(data)
            offset=OFFSETS[volume]
            printed=(pno-offset) if pno>offset else ''
            rows.append({
                'volume':volume,'physical_page':pno,'printed_page':printed,
                'image':target.as_posix(),'width':width,'height':height,
                'method':method,'sha256':sha256(data),
            })
    with args.manifest.open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,fieldnames=list(rows[0]))
        wr.writeheader(); wr.writerows(rows)
    print(f'images={len(rows)} manifest={args.manifest}')

if __name__=='__main__':
    main()
