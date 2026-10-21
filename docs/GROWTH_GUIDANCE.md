# 성장 목표·최종보스 준비 안내

## 범위와 선택 호출
- 기준 main `fbe7e98725dee6e87a9983cdd48c34ec36f18747`, 시작 시 열린 PR 없음. 기존 grovebound 및 다른 Work의 미커밋 변경과 사용자 저장은 보존했다.
- 중간 위험도의 읽기 전용 UI 연결. 총괄은 `integrate/growth-guidance`에서 제품 5파일과 공통 인계를 소유한다. 기획은 `docs/design-reviews/growth-guidance.md`, 독립 QA는 `test/growth-guidance` 별도 worktree에서 집중검사/격리 fixture를 소유했다. 기획의 단일 검토 문서는 총괄과 동시 편집하지 않았다.
- 기획 호출: 목표/정보 순서와 공략 공개 범위 판단. QA 호출: 실제 판정과 표시가 어긋날 위험·여러 화면 경계 독립 확인. 별도 개발·전투·캠페인·아트 역할 생략: 제품 수정이 하나의 표시 연결에 의존하고 도메인/수치/에셋을 바꾸지 않는다. 외부 웹 조사는 기존 실제 정책 연결로 충분해 생략했다.
- 터미널 GitHub DNS 실패는 커넥터로 대응했다. 원격 대비 변경25개 파일의 blob SHA와 전체 기준 tree `1c80099cf765c9a420c573fd54a15a6c817a323a`를 검증했고 서명 포함 기준 커밋 SHA를 동일하게 복원했다. 임의의 오래된 checkout을 최신 main으로 취급하지 않았다.

## 연결한 행동
- 기존 메뉴 하단과 세계지도 우측: 다음 일반 목표 → 승급/합성/능력 선택/출전 부족 상태 → 실제 이용 가능한 추천 탐험. 일반 완료를 최우선으로 표시하고 심층 해금과 구현 준비 중을 구분한다.
- `ui/growth_guidance.gd`는 읽기 전용 모델이다. 승급은 `promotion_preview`, 목표 재료는 `target_plan`, 합성 가능은 `material_error`와 실제 `preview`, 추천/보상은 `available`/`growth_replay`/`rewards`를 재사용한다. 추천은 최초 완료한 후반 성장 경로를 안정적으로 제시하며 최적 효율 순위나 확정 필요 횟수를 주장하지 않는다.
- 목표 육성 확인: 부족분 `max(0, cost-materials)`와 기존 지도 연결. 만렙3성은 개별 합성 후보이며 4~6성에 합성 재료 충족이라고 잘못 표시하지 않는다. 기존 합성 후보/보조 수와 계곡 교감종수 안내를 보존했다.
- 4성 보유·선택 대기·대기/보관·출전4를 구분한다. 다른 보유 동료의 선택 대기도 실제 출발 차단과 동일하게 안내한다. 출전 완료는 승리를 보장하는 판정이 아니다.
- 5-8 지도에는 피해차단 → 가까이서 선택 완료4성+ 스킬 → 6초 해제/집중 및 예고 회피를 안내한다. 전투 HUD는 현재 갑주/해제 시간을 표시한다. 전체 패턴 순서/최적 조합/공격 수치 공략은 추가하지 않았다. 새 입장 제한·조건은 없다.
- 성장/합성/승급/보상/갑주/능력값·저장키/스키마·RNG·동료·주인공·진행·작은 캐릭터/시야·기존 UI를 보존한다. 신규 화면/팝업/알림/자동소비/자동출발은 없다. 계약 실질 변경과 마이그레이션은 없다.

## 검증과 증거
- Windows Godot 4.7.2 Standard. 전체 `tools/audit_suite.py --workspace-saves` 49/49 통과: 저장 왕복·실패 무변경·동료/캠페인 회귀 포함. 결과 `growth-guidance-tests.json`.
- 독립 집중검사는 `tools/test_growth_guidance.gd`. 실제 정책 경계, 즐겨찾기/중복ID/동행 보조, 진행0/8/24/25/39/40, 4성 선택/보관/대기/출전, 재료0/cost−1/cost, 표시 열기 전후 payload/RNG, 화면 포함/겹침과 HUD 상태를 확인한다. 최종 독립 집중검사 1,907개 PASS. 보스 패널이 기존 출발 스토리를 가린 문제도 패널 아래12px 재배치하고 캠프/비보스 위치복귀를 검사했다.
- 실제 PNG: `growth-guidance-goal.png`, `materials.png`, `synthesis.png`, `completed.png`, `boss.png`, `closed.png`, `open.png` (모두 접두사 growth-guidance-). 생산 UI/전투HUD를 호출한 준비 상태이며 임의 모형 이미지가 아니다. `animation/growth_guidance_review.gd`는 사용자 저장 읽기/쓰기 override로 격리한다. 움직임/전투 성능 변경 없음.
- 최초 회귀46/48: 교감종수 라벨 제거로 기존 assert 후 타임아웃, 합성 후보 수 라벨 누락. 기존 정보를 복원해 전체49/49로 재검증했다. 실패를 검사 완화로 숨기지 않았다.
- 최초 제한 호스트 import의 ObjectDB profiler `user://` 접근 오류는 테스트 프로세스 APPDATA를 workspace `.qa-appdata`로 지정해 재실행 시 해소했다. Parse/SCRIPT ERROR 없음. 기존 일부 오디오 ObjectDB 종료 경고는 회귀 결과에 보존한다.
- 사람 이해도·직접 장기 플레이·모바일 터치/실기기·경제 적정성은 미검증이다. 준비 상태 캡처/자동검사를 사람 이해도 검증으로 보고하지 않는다.

## 재실행과 후속
- `python tools/audit_suite.py --godot GODOT_PATH --workspace-saves --out docs/growth-guidance-tests.json`
- `GODOT --headless --path . --log-file ABSOLUTE_LOG_PATH --script tools/test_growth_guidance.gd`
- `GROVE_GROWTH_SCREEN=goal/materials/synthesis/completed/boss/closed/open`, `python tools/preview.py --godot GODOT_PATH --scene res://animation/growth_guidance_review.tscn --out docs/growth-guidance-STATE --mode still --frames-only --skip-import`. 3프레임 중 마지막 PNG를 사용한다. 제한 호스트에서 APPDATA를 격리하고 필요 시 정확한 shader-cache 경고만 허용한다.
- `python tools/check_handoff.py`와 기준 SHA `--base`를 실행한다. 원격 PR/CI/병합 결과는 PR과 최종 보고에서 실제 확인한다.
- 2번 경제 검토는 기획 문서의 관찰표를 사용한다: 첫4성 목표 발견 시점, 실제 재탐험 경로/횟수/시간, XP 손실/승급 회복, 재료 수급·소비·잔량, 합성 후보와 잠금/동행 소모, 골드·장비·지원스킬 병목, 보스 실패 원인(성장/선택·편성/거리·스킬/회피)을 분리한다. 승인15~20회를 모든 사람의 보장 횟수로 취급하지 않는다.
- 사람 플레이에서 안내를 보고 다음 행동을 고르는지 확인 후 경제 검토를 진행한다. 이번 후속에 심층/입장재화나 수치 변경을 자동 착수하지 않는다.
