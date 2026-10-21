# 장비 발견·목록·지도 시각 개선

## 기준과 범위
- 원격 main 5bed96131eb1879d53a188f38e82de91152d4825, tree e15c2d05c8830f579ace0e3af99518536f697e04. 로컬 squash 전 5a790f3의 전체 tree 동일 확인. 열린 PR 없음. 기존 다른 worktree 미커밋 변경 보존. 실행기 작업 목록 조회 실패로 기존 디렉터리·브랜치·인계 확인 후 별도 worktree 사용.
- 중간 위험 UI/아트 작업. 기획 D1~D6 채택, 장비 UI와 지도는 비중복 소유 파일에서 병렬, 총괄 main/획득결과/아이콘 연결, 작성자와 다른 독립 QA 선택. 도메인·저장 스키마·드롭/보상·RNG·전투/성장/캠페인 해금·카메라·캐릭터 크기는 보존.
- 기획/장비 UI/지도 UI·아트/독립 QA를 선택 호출. 전투·성장·캠페인 데이터 별도 개발과 웹 조사는 관련 수치 변경이 없고 기존 경제 분석으로 판단 가능해 생략.
- 기준 및 수용 기준: ../design-reviews/equipment-map-visuals.md. 별도 UI 스키마 계약 변경 없음. report.equipment는 저장하지 않는 이번 탐험 보고서의 확정 획득 스냅샷이며 사용자 저장 필드를 추가하지 않음.

## 구현·검증
- `ui/equipment_inventory.gd`는 표시 전용 목록/정렬/장착 비교이며 명령은 기존 `Hero.plan`과 confirm/commit으로 전달한다. 무기1·방어구1·부적2, 장착 판매 금지/캠프 제한/실패 무소모를 유지한다.
- `ui/equipment_icon.gd`는 생성한 RGBA atlas9영역을 사용한다. 생성 행간에 맞춘 명시 영역으로 지팡이 끝/로브 밑단을 보존하며 TextureRect expand_mode를 먼저 설정해 카드 크기를 지킨다. 새 등급/외형 장착 체계는 없다.
- 결과 `equipment`와 `hero_growth`를 최초 저장 완료 시 함께 고정한다. pending 때 확정 목록을 숨기고 성공 재시도 때 한 번만 공개한다. 보상 식/RNG/저장/거래는 수정하지 않는다. 이후 구매/판매는 결과를 바꾸지 않는다.
- 지도는 기존 노드 좌표/콜백을 유지하며 실제 available 결과로 잠금 장식만 연결한다. 지형 장식은 입력을 가로채지 않는다.
- 전체 `tools/audit_suite.py --workspace-saves` 50/50 PASS: 구세이브·왕복·실패 무변경·동료/캠페인/성장 회귀 포함. 결과 `../equipment-map-tests.json`. 주인공 집중50검사, 지도 캠페인 검사와 성장 안내1907검사도 통과했다. Godot4.7.2 Standard import/실행에서 Parse/SCRIPT ERROR 없음.
- 작성자와 다른 QA가 필터/정렬/0·1·36개/끝스크롤·부적2칸 실효 비교·거래 실패·저장 대기/재시도·구매품 오인·지도6상태/legacy/심층 차단을 검사했다. 초기852검사 PASS. 최종 독립검사 수와 판정은 아래 최종 QA에 기록한다.
- QA에서 발견한 탐험 요약의 상점 구매/판매 후 변동을 스냅샷으로 수정했다. 실제 렌더에서 발견한 아이콘 최소크기 겹침을 속성 지정 순서로 수정하고 새 장비/상점/획득/대기 PNG로 재확인했다.
- 실제 생산 UI 캡처: `../equipment-map-inventory.png`, `shop.png`, `loot.png`, `pending.png` (모두 equipment-map- 접두사), `../equipment-map-world.png`, `../equipment-map-theme-1.png`~`theme-5.png`. 준비 상태의 Godot 실행이며 생성 시안·사람 플레이가 아니다. 프리뷰 load_game/persist_payload override와 APPDATA로 사용자 저장 격리.
- 인계/문서 링크/범위와 필수 CI/원격 main SHA는 릴리스 시 실제 확인. 기존 일부 테스트 ObjectDB 종료 경고는 JSON에 그대로 기록했다. 새 Parse/SCRIPT/ERROR 없음.
- 사람 재미·장기 드롭경제·모바일 터치/실기기·실제 난이도는 미검증. 모션/전투 변경이 없어 GIF/MP4 대상 아님. 기획 사후 D1~D5 적합, D6은 최종QA/CI 게이트. 필수 결함/검증 실패 시 병합하지 않는다.

## 재실행
```text
python tools/audit_suite.py --godot GODOT_PATH --workspace-saves --out docs/equipment-map-tests.json
GODOT --headless --path . --script res://tools/test_equipment_map.gd
GROVE_EQUIPMENT_SCREEN=inventory/empty/one/shop/loot/pending/no_drop/map0~5
python tools/preview.py --godot GODOT_PATH --scene res://animation/equipment_map_review.tscn --out docs/equipment-map-STATE --mode still --frames-only --skip-import
python tools/check_handoff.py
```
- 제한 호스트에서는 APPDATA를 workspace `.qa-appdata`로 격리한다. 그림 파일만 보는 경우 조작 검증으로 표시하지 않는다.
- 후속은 사람의 목록 찾기/부적 비교/결과 확인/지도 선택과 모바일 터치 관찰이다. 고정9종의 장기 흥미 한계는 이번 UI로 해결했다고 주장하지 않으며 새 옵션·희귀도·수급 변경은 합의 후 별도 구현한다.

## 최종 QA
- 독립 QA 커밋 8f617706d093376ddc1e830ba7edf45b83b2814f, 최종 979검사 PASS, 오류/경고 없음. 제품8파일 hash대조와 최신지도 동기화 후 실행. 증거 ../equipment-map-qa.json. 총괄도 최종 집중검사 재실행979 PASS.
- 10개 실제 캡처 독립 시각검토 완료. 발견2건 수정 후 회귀 통과, 현재 blocking defect 없음. 전체50/50은 마지막 아이콘기하assert 추가 전이며 제품코드는 동일, 수정된 집중검사만 추가 재실행했다.
- PR/CI/원격 main 검증은 원격 결과로 별도 확인한다.
