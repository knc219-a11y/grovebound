# 다음 대화 인계 · 2026-10-20 P1-A/B 수정 후

## 현재 상태
최신 main에서 `AGENTS.md`, `STATUS.md`, 이 문서, `docs/REVIEW_2026-10-20.md` 순서로 읽는다. 검토 때 발견한 **P1-A 공격 방향 / P1-B 귀환 상태 잔류는 수정 완료**다. 마을·공격 원화를 처음부터 다시 만들지 않는다.

- 일반 공격 준비/타격 때 실제 대상의 좌우를 반영한다. 준비 중 대상 교차도 검사했다.
- 마을/결과/재출발 시 행동·채널·보행·피격/쓰러짐 시각 상태와 소생 입력을 정리한다. 기본 지팡이로 복귀하며 마을 위치는 보존한다.
- 전체25/25 PASS: `docs/fix-2026-10-20-tests.json`. 새 회귀 검사 `tools/test_druid_transitions.gd`.
- 실제 격리 Godot6초: `docs/druid-transition-fix.gif` / `.mp4` (좌우 공격·이동·공격 중 마을 귀환). 렌더 오류/영상 디코딩 검사와 화면 확인 완료.
- 자동4경로 결과는 기존과 동일. `docs/fix-2026-10-20-journeys.json`의 attack_facing/town_stale_action confirmed=false. 이 JSON의 confirmed는 버그 재현 여부이며 PASS가 아니다. 정상 기대값은 회귀 검사로 보장한다. 예전 audit JSON/영상은 수정 전 증거다.

## 다음 작업
1. **P1-C 선택 옆길의 실제 선택성**: 본선 전용 자동 동선에서도 북/남 무리가 함께 교전한다. `trail.gd` 배치와 동료 탐색/범위/진입 조건을 함께 검토하고 본선·옆길 선택 재현 검사와 실제 이동 영상을 만든다. 수치부터 바꾸지 않는다.
2. **P2-A 일반 공격음**: 주인공 `support` 이벤트에 음원 프로필이 없어 무음. 명시 지원 스킬과 구분하고 실패 입력 무음/중복음/6음성 상한을 유지한다.
3. **P2-B 밀집전 가독성**: 숫자·방어 문구·스킬명의 위치/개수/우선순위 조정. 작은 캐릭터/카메라와 피해 판정 유지.
4. 위 수정 후 첫 출발 준비/성장/교감 운 재검토. 사용자 합의 없이 드랍/성장/보상/등급을 변경하지 않는다.

## 보존·제한
- 드루이드 전체72px/몸체60px, 일반 멧돼지48px, 논리1440×810/월드2900×1650. 카메라 줌/캐릭터 확대로 대체하지 않는다.
- 승인 도트풍·사냥터·독립 지팡이 API·활동4/준비6·기존 세이브/옵션/특성/등급을 보존한다.
- iPhone 터치/음향/성능, Windows, 사람의 연속 완주 시간은 미검증. 자동 경로를 사람의 난이도/성공률로 해석하지 않는다.
- headless 오디오 ObjectDB 종료 경고는 잔여 항목이며 지속 메모리 누수라고 단정하지 않는다.
- 관련 없는 .import/.uid/project.godot 변경은 커밋하지 않는다. GitHub ref 확인 후 반영 완료라고 말한다.

## 재현
- `python tools/audit_suite.py --godot PATH --out docs/fix-2026-10-20-tests.json`
- `GODOT --headless --path . --script tools/audit_journey.gd` → fix journeys JSON.
- `tools/preview.py` + `res://animation/druid_transition_review.tscn`. Linux는 Xvfb 필요. 사용자 세이브를 쓰지 않는 격리 장면이다.

## 시작 프롬프트
```text
https://github.com/knc219-a11y/grovebound 최신 main의 AGENTS.md, STATUS.md, docs/NEXT_SESSION.md, docs/REVIEW_2026-10-20.md를 읽고 P1-C 선택 옆길 자동 교전부터 이어가자.
P1-A/B는 수정됐다. 본선만 걸을 때 북/남 선택 무리를 의도치 않게 전부 잡지 않도록 동선/탐색/진입 조건을 검토해줘.
현재 크기·카메라·그림풍·지팡이·세이브·성장/수집 수치는 유지하고, 실제 Godot 영상과 회귀 검사 후 GitHub main/인계 문서를 갱신해줘.
iPhone 실기기 검증은 아직 미완료다.
```
