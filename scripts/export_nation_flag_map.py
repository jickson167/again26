#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""localStorage 매핑 또는 기존 JSON을 nation_flag_map.json으로 정리."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "web/data/nation_flag_map.json"

EXTRA_ALIASES: dict[str, list[str]] = {
    "대한민국": ["한국", "Korea", "KOR", "South Korea"],
    "일본": ["Japan", "JPN"],
    "세르비아": ["Serbia", "セルビア"],
    "중국": ["China", "CHN"],
    "미국": ["USA", "United States"],
    "잉글랜드": ["England", "ENG"],
    "프랑스": ["France", "FRA"],
    "독일": ["Germany", "GER"],
    "스페인": ["Spain", "ESP"],
    "브라질": ["Brazil", "BRA"],
    "아르헨티나": ["Argentina", "ARG"],
    "네덜란드": ["네델란드", "Netherlands", "NED", "Holland"],
    "코트디부아르": ["코르티부아르", "Ivory Coast", "Cote d'Ivoire", "Côte d'Ivoire"],
    "튀르키예": ["터키", "Turkey", "Türkiye", "TUR"],
    "체코": ["체코공화국", "Czech", "Czech Republic", "CZE"],
    "우크라이나": ["Ukraine", "UKR"],
    "보스니아 헤르체고비나": [
        "보스니아-헤르체고비나",
        "Bosnia and Herzegovina",
        "Bosnia",
        "BIH",
    ],
    "기니": ["기니공화국", "Guinea", "GUI"],
    "포르투갈": ["Portugal", "POR"],
    "인도네이사": ["인도네시아", "Indonesia"],
}


def build_export(entries: dict) -> dict:
    flags: list[dict] = []
    by_name_ko: dict[str, str] = {}
    by_alias: dict[str, str] = {}

    for flag_id in sorted(entries.keys()):
        entry = entries[flag_id]
        name_ko = (entry.get("name_ko") or "").strip()
        if not name_ko:
            continue
        aliases = list(
            dict.fromkeys(
                [
                    *(entry.get("aliases") or []),
                    name_ko,
                    *(EXTRA_ALIASES.get(name_ko) or []),
                ]
            )
        )
        item = {
            "flag_id": flag_id,
            "file": entry.get("file") or f"{flag_id}.png",
            "name_ko": name_ko,
            "name_en": (entry.get("name_en") or "").strip(),
            "aliases": aliases,
        }
        flags.append(item)
        by_name_ko[name_ko] = flag_id
        for alias in aliases:
            a = alias.strip()
            if a:
                by_alias[a] = flag_id

    return {
        "version": 1,
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "flags": flags,
        "lookup": {"by_name_ko": by_name_ko, "by_alias": by_alias},
    }


def main() -> None:
    if OUT.exists():
        data = json.loads(OUT.read_text(encoding="utf-8"))
        entries = {f["flag_id"]: f for f in data.get("flags", [])}
    else:
        entries = {}

    if not entries:
        raise SystemExit("매핑 데이터 없음 — flag_nation_mapper에서 JSON 다운로드 후 다시 실행")

    OUT.write_text(
        json.dumps(build_export(entries), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"{OUT} ← {len(entries)}개")


if __name__ == "__main__":
    main()
