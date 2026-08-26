from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
errors=[]
for n in range(1,27):
    p=root/'chapters'/f'ch{n:02d}.tex'
    if not p.exists(): errors.append(f'missing {p.relative_to(root)}')
for rel in ['frontmatter/upper.tex','frontmatter/lower.tex','backmatter/upper.tex','backmatter/lower.tex','STYLE_GUIDE.md','examples/style-example.tex','TASKS.md']:
    if not (root/rel).exists(): errors.append(f'missing {rel}')
for p in root.rglob('*.tex'):
    t=p.read_text(encoding='utf-8')
    bad=[hex(ord(c)) for c in t if ord(c)<32 and c not in '\t\n\r']
    if bad: errors.append(f'{p.relative_to(root)} control chars: {bad[:5]}')
print('errors=',len(errors))
for e in errors: print(e)
sys.exit(1 if errors else 0)
