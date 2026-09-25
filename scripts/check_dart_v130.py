#!/usr/bin/env python3
"""Быстрая проверка Dart-файлов: баланс скобок, кавычек, версии."""
import re
import sys
from pathlib import Path

ROOT = Path("/home/z/my-project/time_to_grow")

def strip_strings_comments(src: str) -> str:
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            i = n if j == -1 else j + 2
        elif c in ("'", '"'):
            q = c
            i += 1
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i] == q:
                    i += 1
                    break
                if src[i] == "$" and i + 1 < n and src[i + 1] == "{":
                    depth = 1
                    i += 2
                    while i < n and depth:
                        if src[i] == "{":
                            depth += 1
                        elif src[i] == "}":
                            depth -= 1
                        i += 1
                    continue
                i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)

def check(path: Path) -> list[str]:
    src = path.read_text(encoding="utf-8")
    s = strip_strings_comments(src)
    errs = []
    for a, b in [("{", "}"), ("(", ")"), ("[", "]")]:
        if s.count(a) != s.count(b):
            errs.append(f"{path.name}: {a}{b} imbalance {s.count(a)}/{s.count(b)}")
    return errs

def main() -> int:
    errs: list[str] = []
    dart_files = sorted(ROOT.rglob("*.dart"))
    for f in dart_files:
        errs += check(f)
    pubspec = (ROOT / "pubspec.yaml").read_text()
    m = re.search(r"^version:\s*(.+)$", pubspec, re.M)
    print(f"dart files: {len(dart_files)}, pubspec version: {m.group(1) if m else '?'}")
    for e in errs:
        print("ERR", e)
    print("OK" if not errs else "FAIL")
    return 0 if not errs else 1

if __name__ == "__main__":
    sys.exit(main())
