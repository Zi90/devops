#!/usr/bin/env python3
"""README.md 안의 결과 표시 자리에 실행 결과 파일 내용을 채워 넣는다.

README에 아래처럼 적어 두면
    <!-- RESULT: results/04-ps-healthy.txt -->
    <!-- /RESULT -->
두 줄 사이가 해당 파일 내용(```text 블록)으로 바뀐다. 여러 번 실행해도 된다.
사용법: python3 fill-readme.py ~/devops/week07/README.md [...]
"""
import re
import sys
from pathlib import Path

PATTERN = re.compile(r"(<!-- RESULT: (?P<path>\S+) -->\n)(?P<body>.*?)(<!-- /RESULT -->)", re.S)


def fill(readme: Path) -> None:
    text = readme.read_text(encoding="utf-8")
    missing = []

    def repl(m: re.Match) -> str:
        src = readme.parent / m.group("path")
        if src.is_file():
            body = src.read_text(encoding="utf-8", errors="replace").rstrip()
            block = f"```text\n{body}\n```\n"
        else:
            missing.append(m.group("path"))
            block = "_(아직 실행 결과 없음)_\n"
        return m.group(1) + block + m.group(4)

    new = PATTERN.sub(repl, text)
    readme.write_text(new, encoding="utf-8")
    status = "OK" if not missing else "결과 없음: " + ", ".join(missing)
    print(f"{readme}: {status}")


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        p = Path(arg).expanduser()
        if p.is_file():
            fill(p)
