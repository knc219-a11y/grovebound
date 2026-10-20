# 탐험 지도와 계곡 1-1~1-8

2026-10-20. main 43f9d74541cdcc10e68239cdc19344b9d5e31727에서 시작. 이 문서는 지도/일반 계곡8개 구현 당시 기록이다. 후속 채석장8개 확장과 최신16스테이지/검증은 docs/QUARRY_ROUTES.md를 따른다. 40/120개 전체 구현으로 해석하지 않는다. 세계관·진행 방향은 PROJECT_SETTINGS.md, 후속 전체 설계는 WORLD_CAMPAIGN_DESIGN.md를 따른다.

## 플레이

마을 동쪽 사냥길 또는 메뉴의 사냥길 선택 → 세계 지도 → 초록물 계곡 → 스테이지 노드 선택 → 상세/보상 확인 → 출발. 노드 선택만으로 출발하지 않는다. 앞 스테이지 완료로 다음 길이 열리며 완료한 길은 재방문한다. 4번은 중간보스,8번은 테마 보스다.

본선 길목을 모두 제압한 뒤 물길 표식에 접근해 **F/화면의 길 잇기**로 완료한다. 보스만 우회해 잡거나 출구에 먼저 도착해서 완료할 수 없다. 보스는 앞 길목 제압과 공터 접근 후 등장한다. 남은 야수와 교감한 뒤 완료할 수 있고,옆길 사슴/거북은 선택이며 완료 필수가 아니다. 쓰러진 동료가 출구 가까이 있어도 길 잇기는 가능하다.

## 계곡 구성과 현재 보상

승인된 기존 수식을 그대로 사용한다: 보상 적당 동행6 각각12+적레벨×4 XP,일반 재료1/보스5/클리어10,일반 야수 교감15%·1성. 추가 약한 무리는 제압만 늘리고 별도 보상은 없다. 기존 전역 성장/5·6성 능력/확률은 변경하지 않았다. 지역을8개의 독립 탐험으로 나누므로 테마 전체의 보상합은 옛 단일 계곡과 같지 않다.

| 스테이지 | 이름 | 적 레벨 | 본선 XP/동행 각각 | 본선+완료 재료 | 역할 |
| --- | --- | --- | --- | --- | --- |
| 1-1 | 흉포한 발자국 | 1 | 48 | 13 | 소규모 협동 |
| 1-2 | 두 갈래 물길 | 1 | 64 | 14 | 세 계열 혼합 |
| 1-3 | 풀밭의 집결 | 2 | 100 | 15 | 무리/범위기 |
| 1-4 | 가시등의 공터 | 2 | 60 | 17 | 중간보스450HP·발구르기 |
| 1-5 | 메마른 샛물 | 2 | 100 | 15 | 굽은 동선/혼합 |
| 1-6 | 이방인의 흔적 | 3 | 144 | 16 | 다른 공격 거리 |
| 1-7 | 샘으로 가는 길 | 3 | 168 | 17 | 네 길목 종합 |
| 1-8 | 초록물의 샘 | 일반3/보스4 | 124 | 19 | 기존 우두머리850HP·강타/돌진 |

합계808XP/동행 각각·126재료,교감/작별/옆길 제외. 각 스테이지 옆길2마리는 별도XP/재료를 주며 해당 적레벨 수식을 따른다. 새 재료재화나 교감성급 가중치는 추가하지 않았다. 중간보스는 기존 멧돼지 보스 원화를 재사용하고 발구르기만 사용한다. 최종보스는 기존 원화와 발구르기/돌진을 유지한다. 새 종/새 야수 동료/새 진화스킬은 없다.

각 구간의 출발 목표와 완료 문장은 계곡의 흉포화→막힌 물길→채석장 흔적으로 이어진다. 기존 승인 배경과 작은 소품을 공유하며 길목 위치/무리/이동 방향/표식/쉼터를 바꾼8개 독립 출발 단위다. 8개 새 배경 원화를 제작한 작업은 아니다. 캐릭터·카메라·72px 주인공·활동4/준비6을 보존한다.

## 구현 경계와 호환

- campaign_routes.gd: normal/depth/challenge + theme1..5 + stage1..8 좌표,명시적 구현 여부,순서,보상 원장,계곡 데이터. 심층/도전과 일반2~5테마8분할은 준비 중으로 표시하고 출발을 막는다.
- valley_trail.gd: 스테이지별 길목/옆길/쉼터/보스 진입/출구/미니맵. ui/exploration_map.gd와 campaign_menu.gd는 세계→테마 지도,선택/잠금/보스 표식/상세/출발을 표시한다.
- 저장version2 안에 campaign_progress.version1/cleared의 명시적 difficulty/theme/stage를 추가한다. 옛 cleared_stages의1/2/3을 새로운 일련번호로 재해석하지 않는다. 원본 백업 후 기존 완료 지역을 해당 일반테마1~8완료로 이관한다. unlocked=true의 계곡완료 의미와 동료ID/종/성급/레벨/XP/특성/옵션/즐겨찾기/편성을 유지한다.
- 새 진행을 저장한 뒤에는 그 기록을 기준으로 읽는다. 중복/간격/숫자형을 정규화하고 재로드는 멱등적이다. 알 수 없는 진행 버전은 원본을 덮어쓰지 않게 저장을 차단한다.
- 계곡1-8완료가 기존 지역 해금에도 반영된다. 채석장/묘역 지도에는 **기존 사냥터 탐험**을 남겨 과거 해금/재방문/보스 진행을 유지한다. 기존 지역 탐험 완료도 새 테마 기록으로 연결한다. 새2-1~2-8/3-1~3-8 구현이 완료됐다는 의미는 아니다.
- 새 완료 보너스10과 진행좌표/기존해금은 한 payload로 저장 성공 후 메모리에 반영한다. 쓰기실패는 재시도할 수 있고 중복제출은 보너스를 중복 지급하지 않는다. 개별 처치 보상은 기존 처치 시 저장 정책을 유지한다. 합성/진화 선택 대기 동료가 있으면 출발을 막는다.
- animation/pixel_gameplay_preview.gd는 save_game뿐 아니라 persist_payload도 차단해 격리장면의 트랜잭션이 사용자 저장에 도달하지 않게 한다.

## 확인한 범위

- Godot4.7.2 전체39/39 PASS: campaign-map-tests.json. 마지막 지도 줄바꿈/쉼터 문구 수정 후 지도 회귀 집중검사도 PASS. 기존3→4/4→5/5→6 검사를 포함한다.
- test_campaign_routes.gd: 지도 실제 버튼 콜백·노드 선택만으로 미출발·잠긴/미구현 출발 차단·상세 텍스트 폭·계곡8개 전투 보상 원장·준비6 XP·앞 길목/보스/출구·저장실패 롤백/재시도·중복완료·구지역 백업/실제파일 왕복/동료 보존/멱등성·미래버전 덮어쓰기 방지.
- audit_valley_routes.gd: 첫인연3종×시드2개의 동일동료/성장 연속6경로,스테이지48/48 완료: campaign-map-journeys.json. 튜토리얼 적 제압만 단축하고 이후 실제update_game dt=.05/이동/Q/E/스킬/교감/소생/예고회피/출구 상호작용. 고레벨 팀·육성 재료를 주입하지 않았다. 가까운 교감 기회를 실제 수집하므로 추가 인연을 전부 건너뛴 검사는 아니다.
- 봇 기준 구간9.9~22.5초,최저 주인공HP69.1/180,동료 쓰러짐0,최초 동료는 최종Lv7. 빠른 자동 입력과 제한된 시드 결과이며 사람의 클리어 시간/성공률/장기 육성 부담이 아니다. 5·6성 성장 병목은 이번 초급 기반만으로 해결됐다고 주장하지 않는다.
- 실제 Godot OpenGL/NVIDIA 렌더: campaign-map-world/stages/locked/result.png. 텍스트 넘침을 수정해 다시 캡처하고 확인했다.
- 실제 midboss8초/boss12초 GIF·MP4: campaign-map-midboss.*,campaign-map-boss.*. Lv3 준비팀과 앞 무리 제압 상태의 격리된 보스 QA다. 전체 클리어 영상이나 사용자 실제 진행이 아니다. 기존 모션/공격예고/회피/스킬/체력 변화를 확인했다. MP4는 무음이다.
- Windows sandbox의 user:// 쓰기 제한 때문에 --workspace-saves가 기존5개 저장검사의 테스트 경로만 일시적으로 res://.qa-data로 바꾸고 finally에서 복구한다. production save 경로는 바꾸지 않는다. 실제 렌더의 정확한 shader cache 폴더 생성불가 메시지는 기록하고 허용했다. SCRIPT/Parse ERROR는 없다. 기존 headless 전투오디오 ObjectDB 종료경고는 남아 있다. 사람·iPhone·다양한 기기/장기 성장 검증은 남았다.

## 재실행

```text
python tools/audit_suite.py --godot GODOT --out docs/campaign-map-tests.json
# user:// 제한 호스트만 위 명령에 --workspace-saves 추가
GODOT --headless --path . --script res://tools/audit_valley_routes.gd
python tools/preview.py --godot GODOT --scene res://animation/campaign_map_stages_review.tscn --out docs/campaign-map-stages --mode still
python tools/preview.py --godot GODOT --scene res://animation/campaign_map_midboss_review.tscn --out docs/campaign-map-midboss --seconds 8
python tools/preview.py --godot GODOT --scene res://animation/campaign_map_boss_review.tscn --out docs/campaign-map-boss --seconds 12
python tools/check_handoff.py
```

world/locked/result도 같은 review 장면과 preview.py로 캡처한다. FFmpeg 없는 Windows에서는 preview.py --frames-only와 OS Media Foundation/Pillow로 PNG→MP4/GIF를 인코딩했다. MP4의 실제 디코딩과 GIF 프레임/길이,실제 원본의 여러 시점을 확인했다. --allow-shader-cache-warning은 정확한 cache 폴더 경고 한 줄만 허용하며 다른 오류는 숨기지 않는다.

채석장2-1~2-8 확장은 QUARRY_ROUTES.md에서 구현했다. 다음은 묘역3-1~3-8,그 뒤4/5테마·일반 전체 성장곡선이다. 상위 난이도는 일반 전체 수급을 확인한 후 구현한다.
