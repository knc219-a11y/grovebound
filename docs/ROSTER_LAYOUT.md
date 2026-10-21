# 동료 관리 좌우 레이아웃

## 범위와 기준
- 기준 원격 main: d29f4d61bcf56d4115bcdd39da7bca1b2d94f306. 시작 시 열린 PR 없음. 기존 grovebound 폴더의 미커밋 변경과 sources는 수정하지 않았다.
- UI: work/roster-ui, feat/companion-roster-layout, 소유 ui/companion_roster.gd.
- 독립 QA: work/roster-qa, test/companion-roster-layout, 소유 tools/test_roster_layout.gd 및 animation/roster_layout_review.gd/.tscn.
- 통합 리드: work/roster-integration, integrate/companion-roster-layout, 소유 main.gd, 공통문서/계약/증거. 모든 worktree는 같은 기준 SHA에서 시작했다.
- UI/QA 준비를 실제 병렬로 실행했다. 테스트는 새 콜백 연결에 의존하므로 실행/최종 검토는 통합 후 순차 진행했다. 최종 변경은 integration PR로 제출한다. 독립 모듈만의 미연결 상태를 제품 완료로 간주하지 않는다.
- 완료 기준: 9개 카드와 별/이미지, 출전4/대기2 분리, 선택→배치/교체, 필터/정렬/기존 액션 보존, 저장실패 무변경, 구세이브/전체회귀, 실제 렌더와 독립검토, CI 및 원격 병합확인.

## 동작과 보존
- 왼쪽 3열 카드 표에서 9마리 동시 표시. 이미지·실제 별·이름·레벨·역할·편성 상태. 오른쪽 4+2 슬롯은 색과 제목으로 구분하며 선택한 동료의 상세/비교·즐겨찾기·육성·동행해제·작별을 별도 표시한다.
- 왼쪽 선택 후 목적 슬롯을 누른다. 편성 동료는 서로 교체, 보관 동료는 대상 슬롯 교체. 선택 없는 슬롯 클릭은 해당 동료 선택이다. 같은 슬롯은 선택 해제한다.
- 기존 저장은 빈 구멍 없는 순서 배열이다. 스키마를 바꾸지 않고 비어 있는 칸을 누르면 앞쪽 출전부터 추가한다. 해제하면 뒤 동료가 앞당겨지며 상태를 즉시 갱신한다. 빈칸 tooltip에 순서를 명시했다.
- 캠프는 전체 동료, 탐험 비전투는 기존 동행만 표시/교체한다. 탐험 교체는 기존 unit의 HP·쿨다운·버프 객체를 이동한다. 전투/튜토리얼 명령은 차단한다.
- 카드 선택·필터·정렬은 원본/편성/RNG를 변경하지 않는다. 종·1~6성·잠금 필터, 순서/최근/성급/레벨 정렬을 제공한다. 선택/잠금 조작은 스크롤을 유지한다.
- 기존 편성·즐겨찾기 명령에서 발견한 저장 전 메모리변경을 저장 성공 후 반영하도록 보완했다. 파일실패/차단 때 기존 파티/잠금/파일/RNG를 보존한다.
- root v2 + hero v1와 모든 저장키·동료ID·종·특성·옵션·진화·주인공/일반40 진행/경제/밸런스/작은캐릭터·시야 보존. 선택/스크롤은 휘발성 UI 상태다. 이 변경은 기존 UI 표시/명령 계약 내 내부 콜백 연결이며 새 공유 도메인 API/저장 계약은 도입하지 않는다.
- 문서의 예전 '상단6칸/아래 목록'을 현재 좌우 구성으로 갱신했다. MULTI_AGENT_DEVELOPMENT의 첫 입장재화 파일럿 기록보다 현재 사용자 요청을 우선한다. 입장재화·심층·미정 밸런스는 추가하지 않았다.

## 검증
- Godot 4.7.2 Standard, Windows 제한 호스트. 신규 test_roster_layout 361/361 PASS, 기능 작성자와 다른 QA가 별도 worktree에서 실제 실행 및 소스/PNG 독립검토했다. blocking defect 없음.
- 전체 audit_suite 48/48 결과는 roster-layout-tests.json. 구세이브 normalize, JSON 정수ID 정규화, 실제파일 왕복, 저장 차단/없는디렉터리 실패, 동료·주인공·캠페인 보존, 반복교체·stage HP/쿨다운 참조 보존을 포함한다.
- 최초 신규검사는 JSON의 float 배열과 메모리 int 배열을 직접 비교해1건 실패했다. 생산 SaveData.normalize로 실제 저장 형식 검사로 교정했다. 제품 저장 손실 결함이 아니며 실패를 숨기지 않는다.
- 실제 Godot 렌더: roster-layout-full.png, selected.png, partial.png, empty.png, field.png (모두 접두사 roster-layout-). 생산 open_roster를 사용한30마리 격리 fixture이며 사용자 저장 read/write override 차단. 3프레임 캡처 중 마지막 프레임을 보관했다. 모션 변경 없음.
- headless 집중검사 SCRIPT/Parse ERROR 없음. 전체회귀의 기존 audio ObjectDB 종료 경고는 결과JSON에 그대로 남긴다. 렌더는 제한호스트의 정확한 shader cache user:// 경고만 허용했다. 상대 log 경로가 user://C: 디렉터리 오류를 유발해 절대 log 경로로 실행했다.
- 미검증: iPhone/Android 터치·실기기 성능, 사람의 장기 수집/실제 저장 플레이 체감. 자동 콜백·준비 상태 QA를 사람 플레이 완료로 표현하지 않는다.

## 재실행과 후속
- python tools/audit_suite.py --godot GODOT_PATH --workspace-saves --out docs/roster-layout-tests.json
- GODOT --headless --path . --log-file ABSOLUTE_LOG_PATH --script tools/test_roster_layout.gd
- python tools/preview.py --godot GODOT_PATH --scene res://animation/roster_layout_review.tscn --out docs/roster-layout-full --mode still --frames-only --skip-import --allow-shader-cache-warning
- GROVE_ROSTER_SCREEN=full/selected/partial/empty/filtered/field로 상태를 선택한다. frames-only의 capture00000002.png가 실제 마지막 프레임이다.
- python tools/check_handoff.py 및 --base d29f4d61bcf56d4115bcdd39da7bca1b2d94f306.
- GitHub 결과는 이 문서의 로컬검증과 구분해 PR과 최종 완료보고에 기록한다. 다음은 사람의 목록/편성 피드백·모바일 터치 확인이며 입장재화는 별도 요청 전 유보한다.
