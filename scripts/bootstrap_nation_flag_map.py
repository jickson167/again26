#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""브라우저 localStorage에서보낸 매핑을 nation_flag_map.json으로 저장."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "web/data/nation_flag_map.json"

EXTRA_ALIASES: dict[str, list[str]] = {
    "대한민국": ["한국", "Korea", "KOR", "South Korea"],
    "일본": ["Japan", "JPN"],
    "세르비아": ["Serbia"],
    "중국": ["China", "CHN"],
    "미국": ["USA", "United States"],
    "잉글랜드": ["England", "ENG"],
    "프랑스": ["France", "FRA"],
    "독일": ["Germany", "GER"],
    "스페인": ["Spain", "ESP"],
    "브라질": ["Brazil", "BRA"],
    "코트디부아르": ["코르티부아르", "Ivory Coast", "Cote d'Ivoire", "Côte d'Ivoire"],
    "남아프리카공화국": ["South Africa", "RSA"],
    "튀르키예": ["터키", "Turkey", "Türkiye", "TUR"],
    "체코": ["체코공화국", "Czech", "Czech Republic", "CZE"],
    "우크라이나": ["Ukraine", "UKR"],
    "네덜란드": ["네델란드", "Netherlands", "NED", "Holland"],
    "보스니아 헤르체고비나": [
        "보스니아-헤르체고비나",
        "Bosnia and Herzegovina",
        "Bosnia",
        "BIH",
    ],
    "기니": ["기니공화국", "Guinea", "GUI"],
    "인도네이사": ["인도네시아", "Indonesia"],
}

FLAGS = [
    {"flag_id": "flags_03", "file": "flags_03.png", "name_ko": "코트디부아르"},
    {"flag_id": "flags_05", "file": "flags_05.png", "name_ko": "남아프리카공화국"},
    {"flag_id": "flags_07", "file": "flags_07.png", "name_ko": "튀르키예"},
    {"flag_id": "flags_09", "file": "flags_09.png", "name_ko": "체코"},
    {"flag_id": "flags_100", "file": "flags_100.png", "name_ko": "알제리"},
    {"flag_id": "flags_101", "file": "flags_101.png", "name_ko": "코르티부아르"},
    {"flag_id": "flags_102", "file": "flags_102.png", "name_ko": "남아프리카공화국"},
    {"flag_id": "flags_11", "file": "flags_11.png", "name_ko": "잉글랜드"},
    {"flag_id": "flags_112", "file": "flags_112.png", "name_ko": "오스트리아"},
    {"flag_id": "flags_113", "file": "flags_113.png", "name_ko": "바레인"},
    {"flag_id": "flags_115", "file": "flags_115.png", "name_ko": "쿠웨이트"},
    {"flag_id": "flags_116", "file": "flags_116.png", "name_ko": "아랍에미리트"},
    {"flag_id": "flags_117", "file": "flags_117.png", "name_ko": "오만"},
    {"flag_id": "flags_118", "file": "flags_118.png", "name_ko": "이스라엘"},
    {"flag_id": "flags_119", "file": "flags_119.png", "name_ko": "이라크"},
    {"flag_id": "flags_120", "file": "flags_120.png", "name_ko": "요르단"},
    {"flag_id": "flags_121", "file": "flags_121.png", "name_ko": "레바논"},
    {"flag_id": "flags_122", "file": "flags_122.png", "name_ko": "팔레스타인"},
    {"flag_id": "flags_13", "file": "flags_13.png", "name_ko": "이란"},
    {"flag_id": "flags_133", "file": "flags_133.png", "name_ko": "우즈베키스탄"},
    {"flag_id": "flags_134", "file": "flags_134.png", "name_ko": "베트남"},
    {"flag_id": "flags_135", "file": "flags_135.jpg", "name_ko": "키르기스탄"},
    {"flag_id": "flags_136", "file": "flags_136.png", "name_ko": "중국"},
    {"flag_id": "flags_137", "file": "flags_137.png", "name_ko": "북한"},
    {"flag_id": "flags_138", "file": "flags_138.png", "name_ko": "인도네이사"},
    {"flag_id": "flags_139", "file": "flags_139.png", "name_ko": "말레이시아"},
    {"flag_id": "flags_140", "file": "flags_140.png", "name_ko": "태국"},
    {"flag_id": "flags_141", "file": "flags_141.png", "name_ko": "필리핀"},
    {"flag_id": "flags_142", "file": "flags_142.png", "name_ko": "뉴질랜드"},
    {"flag_id": "flags_15", "file": "flags_15.png", "name_ko": "우크라이나"},
    {"flag_id": "flags_16", "file": "flags_16.png", "name_ko": "네덜란드"},
    {"flag_id": "flags_17", "file": "flags_17.png", "name_ko": "보스니아 헤르체고비나"},
    {"flag_id": "flags_18", "file": "flags_18.png", "name_ko": "기니"},
    {"flag_id": "flags_19", "file": "flags_19.png", "name_ko": "아르헨티나"},
    {"flag_id": "flags_21", "file": "flags_21.png", "name_ko": "사우디아라비아"},
    {"flag_id": "flags_33", "file": "flags_33.png", "name_ko": "멕시코"},
    {"flag_id": "flags_34", "file": "flags_34.png", "name_ko": "폴란드"},
    {"flag_id": "flags_35", "file": "flags_35.png", "name_ko": "프랑스"},
    {"flag_id": "flags_36", "file": "flags_36.png", "name_ko": "호주"},
    {"flag_id": "flags_37", "file": "flags_37.png", "name_ko": "덴마크"},
    {"flag_id": "flags_38", "file": "flags_38.png", "name_ko": "튀니지"},
    {"flag_id": "flags_39", "file": "flags_39.png", "name_ko": "스페인"},
    {"flag_id": "flags_40", "file": "flags_40.png", "name_ko": "코스타리카"},
    {"flag_id": "flags_41", "file": "flags_41.png", "name_ko": "독일"},
    {"flag_id": "flags_42", "file": "flags_42.png", "name_ko": "일본"},
    {"flag_id": "flags_53", "file": "flags_53.png", "name_ko": "벨기에"},
    {"flag_id": "flags_54", "file": "flags_54.png", "name_ko": "캐나다"},
    {"flag_id": "flags_55", "file": "flags_55.png", "name_ko": "모로코"},
    {"flag_id": "flags_56", "file": "flags_56.png", "name_ko": "크로아티아"},
    {"flag_id": "flags_57", "file": "flags_57.png", "name_ko": "브라질"},
    {"flag_id": "flags_58", "file": "flags_58.png", "name_ko": "세르비아"},
    {"flag_id": "flags_59", "file": "flags_59.png", "name_ko": "스위스"},
    {"flag_id": "flags_60", "file": "flags_60.png", "name_ko": "카메룬"},
    {"flag_id": "flags_61", "file": "flags_61.png", "name_ko": "포르투갈"},
    {"flag_id": "flags_62", "file": "flags_62.png", "name_ko": "가나"},
    {"flag_id": "flags_73", "file": "flags_73.png", "name_ko": "우루과이"},
    {"flag_id": "flags_74", "file": "flags_74.png", "name_ko": "대한민국"},
    {"flag_id": "flags_75", "file": "flags_75.png", "name_ko": "볼리비아"},
    {"flag_id": "flags_76", "file": "flags_76.png", "name_ko": "인도"},
    {"flag_id": "flags_77", "file": "flags_77.png", "name_ko": "이스라엘"},
    {"flag_id": "flags_78", "file": "flags_78.png", "name_ko": "푸에르토리코"},
    {"flag_id": "flags_79", "file": "flags_79.png", "name_ko": "나이지리아"},
    {"flag_id": "flags_81", "file": "flags_81.png", "name_ko": "산마리노"},
    {"flag_id": "flags_93", "file": "flags_93.png", "name_ko": "파라과이"},
    {"flag_id": "flags_94", "file": "flags_94.png", "name_ko": "아이티"},
    {"flag_id": "flags_96", "file": "flags_96.png", "name_ko": "칠레"},
    {"flag_id": "flags_97", "file": "flags_97.png", "name_ko": "콜롬비아"},
    {"flag_id": "flags_98", "file": "flags_98.png", "name_ko": "볼리비아"},
    {"flag_id": "flags_99", "file": "flags_99.png", "name_ko": "이집트"},
]


def main() -> None:
    flags = []
    by_name_ko: dict[str, str] = {}
    by_alias: dict[str, str] = {}

    for item in FLAGS:
        name_ko = item["name_ko"]
        aliases = list(dict.fromkeys([name_ko, *(EXTRA_ALIASES.get(name_ko) or [])]))
        entry = {
            "flag_id": item["flag_id"],
            "file": item["file"],
            "name_ko": name_ko,
            "name_en": "",
            "aliases": aliases,
        }
        flags.append(entry)
        by_name_ko[name_ko] = item["flag_id"]
        for alias in aliases:
            by_alias[alias] = item["flag_id"]

    OUT.write_text(
        json.dumps(
            {
                "version": 1,
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "flags": flags,
                "lookup": {"by_name_ko": by_name_ko, "by_alias": by_alias},
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"{OUT} <- {len(flags)} flags")


if __name__ == "__main__":
    main()
