# 출전국 국기 이미지

파일명 = `flags_XX.png` (게임 내 국가 ID)

| 항목 | 경로 |
|------|------|
| 이미지 | `web/flags/flags_XX.png` |
| 목록 | `web/flags/manifest.json` (자동 생성) |
| 나라 매핑 | `web/data/nation_flag_map.json` |

## 매핑 툴

로컬: http://localhost:8080/tools/flag_nation_mapper.html  
배포: https://jickson167.github.io/again26/tools/flag_nation_mapper.html

국기 이미지 추가 후:

```bash
./scripts/generate_flags_manifest.sh
```

## 규격

- 직사각형 PNG (약 116×78)
- 투명/단색 배경 모두 가능
