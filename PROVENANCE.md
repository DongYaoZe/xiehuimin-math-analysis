# Provenance

This repository is a local LaTeX transcription project for the second edition of **《数学分析习题课讲义》**, compiled by **谢惠民、恽自求、易法槐、钱定边**, 高等教育出版社.

Authoritative local scans used for transcription:

- Upper volume: `谢惠民(2018) - 数学分析习题课讲义(上册)[第2版](1).pdf`
  - 2nd edition, 2018-11, first printing
  - ISBN 978-7-04-049851-6
  - 443 physical PDF pages
  - 50,665,283 bytes
  - SHA-256 `DCF4680FECA1C7A11FFE4C0E57E207FAF31ED1155BC7F28938E8668867F0663C`
- Lower volume: `谢惠民(2019) - 数学分析习题课讲义(下册)[第2版].pdf`
  - 2nd edition, 2019-03, first printing
  - ISBN 978-7-04-051152-9
  - 421 physical PDF pages
  - 41,548,928 bytes
  - SHA-256 `D242C0F047590F4AAE18AC2351736C9E5992BB65A96B28F02613DFB50B8B7A41`

The PDFs are image-only scans (essentially one JPEG page image per PDF page). The repository does **not** track the source PDFs or the extracted full-page scans. `scripts/extract_source_pages.py` reconstructs the local `source-pages/` directory from the scans, while `PAGE_MANIFEST.csv` records the page mapping and image hashes.
