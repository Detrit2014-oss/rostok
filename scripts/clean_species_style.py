import re
p = 'lib/data/species_style.dart'
src = open(p).read()

# 1) Remove named args extra:/build:/ear:/tail:/muzzle:/whiteBelly:/neck:/headScale:/bodyLen:/legLen:
#    from kSpeciesStyles entries. Handle multi-line entries like:
#    PetType.fox: SpeciesStyle(\n body: ..., ear: '...', ...)  → keep body/belly only.
def clean_entry(m):
    inner = m.group(2)
    keep = []
    # split on top-level commas (no nested parens inside args here except none)
    for part in inner.split(','):
        s = part.strip()
        if not s:
            continue
        key = s.split(':')[0].strip()
        if key in ('body', 'belly'):
            keep.append(s)
    return 'SpeciesStyle(' + ', '.join(keep) + ')'

src = re.sub(r"(PetType\.\w+:\s*)(SpeciesStyle\(([^;]*?)\))",
             lambda m: m.group(1) + clean_entry(m),
             src, flags=re.S)

# 2) Fix doc comment about pots.
src = src.replace("/// Растения рисуются в горшочке, а не с лапами.",
                  "/// Растения — комнатные питомцы на грядке (v1.9.0).")
src = src.replace("/// Водные жители — живут в пруду по центру сцены (v1.8.0).",
                  "/// Водные жители — живут в пруду (v1.8.0, пруд справа с v2.1.0).")
open(p, 'w').write(src)
print('cleaned')
