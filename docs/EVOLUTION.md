# 4→5·5→6성 진화 구현과 인계

2026-10-20. 기준 main:08c82fed68e6ed87e249e286e05e8915e2156b18. 사용자 승인값은 docs/PROJECT_SETTINGS.md「5·6성 진화 확정」이 기준이다. EVOLUTION_NEXT_WORK.md는 당시 제안 기록이며 현재 확정/구현은 이 문서와 최신STATUS를 우선한다.

## 사용 흐름

마을 → 동료 관리 → 4성Lv50 동료 육성 → **5성 진화** → 보조 동료 선택 → 소비 대상ID/이름 확인 → 진화 → 역할별 능력3택1 → 최종확정. 선택중 종료하면 같은 동료와 옵션을 복구하고 출발 시 선택창으로 안내한다. 주 동료의 동행/즐겨찾기는 유지되며 보조만 소비한다. 5성Lv50부터60까지 기존 육성/전투XP를 사용한다.

5성Lv60은 **6성 진화** → 다른5성Lv60 보조선택 → 소비ID/기존능력강화값 확인 → 진화 →6성상세. 기존선택자동강화/새선택창없음. Lv60출발·상한70, 기본능력110→130%. 양쪽능력선택완료/다른ID/보조보호/종보존/옵션무재추첨은4→5와같다.

6성총효과: 체력30%, 피해감소12%, 보호막20%·6초, 기본공격/스킬/추격/위력30%, 대기감소15%, 반경30%. 기존5성총효과를대체하며이중곱셈없음. special.evolution의기존ability를유지하고enhanced=true로저장한다. 수치는 special_companions.gd SIX_VALUES에서관리한다.

## 구현

- evolution_rules.gd: RNG 없는 두 마리 스냅샷/보호/정확한성급·레벨·선택완료 검증과 결과 미리보기. 현재7종 야수만 지원한다.
- main.gd/ui/evolution.gd: 재료선택→최종확인→직전검사→소비와선택대기 결과 동시저장→메모리반영. 별도 진화 트랜잭션으로3→4 추첨 경로와 분리했다. 선택 확정도 저장성공 후 반영한다.
- special_companions.gd:4~6성 메타데이터 보존, 기존속성/고유와 별도 special.evolution(version1/state/ability), 상한/기본성장,9개 능력. 추가선택 대기중에도 기존 속성/고유를 지우지 않는다. 기존 정상4성은 그대로이며 재선택/재추첨 없음.
- special_combat.gd: 승인된15%/5초 보호막. 기존공격/회복/받는피해/쿨다운/반경 경로에 새 능력 보너스 적용. 기존7종 강화 스킬 유지.
- ui/special_visual.gd: 표시 크기와 오라 외곽을 유지한 작은5성 문양/안쪽 고리. 배경/카메라/스프라이트 크기 변경 없음.
- 밸런스 조정: special_companions.gd의 EVOLUTION_VALUES와 성장상수, 능력 설명을 함께 수정하고 관련 자동 검사를 갱신한다. 사용자 테스트 후 과한 수치를 조정할 예정이며 현재 장기 밸런스는 미검증이다.

## 검증과 한계

- Godot4.7.2 전체회귀36/36 PASS: docs/evolution-tests.json. 검사 요약은 파일별 기록을 따른다.
- test_evolution.gd: 실제파일 pending/ready 왕복, 옵션/ID/종/특성/속성/고유/편성 보존, 무재추첨, 다른야수종 허용, 정확한성급·만렙·선택완료, 동행/즐겨찾기·중복ID·오래된확인/중복제출 차단, 쓰기실패 시 결과/소비/선택 롤백, 출발차단/복구, 실제버튼 콜백,110/130%/XP상한.
- test_evolution_combat.gd:9개 진화효과 실제피해/회복/보호막/스킬대기/범위, 체력합산/피해곱셈, 처형조건 경계, 보호막비중첩·만료, 잔여폭발1회,7종 강화스킬 유지. 기존4성 검사도 별도로 통과했다.
- 실제Godot docs/evolution-materials.png / evolution-confirm.png / evolution-choice.png / evolution-detail.png, evolution-battle.gif/.mp4. 12초 전투는 준비된 두 팀으로7종을 나눠보는 QA이며6초 팀전환은 시연 전용. 적체력을 높여 효과를 검토한 장면으로 전체성장/완주 검증이 아니다. 저장을 읽거나 쓰지 않는 animation/evolution_*_review.tscn 사용.
- UI 및 영상 디코딩/구간별 실제 프레임 확인. SCRIPT/Parse ERROR 없음. 기존 headless 전투 오디오 ObjectDB 종료경고는 남아 있으며 모바일/사람장기육성·전원차단 내구성은 별도다.
- GitHub CI에 두 진화검사를 연결했다. 원격 실행상태는 로컬 통과와 별도 확인한다.

## 재실행

- python tools/audit_suite.py --godot PATH --out docs/evolution-tests.json
- python tools/preview.py --godot PATH --scene res://animation/evolution_choice_review.tscn --out docs/evolution-choice --mode still
- python tools/preview.py --godot PATH --scene res://animation/evolution_battle_review.tscn --out docs/evolution-battle --seconds 12
- python tools/check_handoff.py

다음: 사용자5·6성플레이피드백. 현행5성수치는유지하고피드백전임의조정하지않는다. 신규특수종/확률/직업/다계열동료AI/지역과 성장재료 수급은 변경하지 않았다.

## 5→6 추가 검증 (2026-10-20)

- 사용자가 EVOLUTION_SIX_NEXT_WORK의9개 강화표 전체를 승인했다. 5성 수치 유지. 기존 능력을6성 총효과로 자동 강화하며 재선택/옵션 재추첨 없음. 정확한 승인값은 PROJECT_SETTINGS「5·6성 진화 확정」을 따른다.
- 정확히5성Lv60 주+부→6성Lv60/상한70. 단계별 미리보기/소비확인/동행6·즐겨찾기 보조보호/직전스냅샷검사/원자적저장/중복소비차단. ID·종·특성·속성·고유·강화스킬·전체옵션·즐겨찾기·편성 보존. 저장실패 시 무변경, 추가비용/RNG 없음.
- Godot4.7.2 전체38/38 PASS: docs/evolution-six-tests.json. 신규 test_evolution_six와 test_evolution_six_combat에서 실제UI콜백·파일왕복·보호변경·저장실패·중복/오래된실행·능력보존·상한70·110/130%와9개 실제전투효과 확인. 기존4→5/3→4 회귀도통과.
- 실제Godot docs/evolution-six-materials.png / evolution-six-confirm.png / evolution-six-detail.png / evolution-six-battle.gif·mp4. 사용자 저장을 읽거나쓰지않는 animation/evolution_six_*_review.tscn. 두팀7종12초의격리QA이며 사람장기육성/모바일/전체스테이지 검증이아니다.
- 로컬Windows 제한으로 저장검사5개의 user://만 일시적으로 res://.qa-data/로 치환해 검사 후 원복했다. 실제파일저장/rename 경로는 그대로 검사했다. audit_suite는 명시적 .godot/audit.log와UTF-8을 사용한다. 실제렌더에서 셰이더캐시 쓰기 불가 경고가 있었으나 이미지/전투가 렌더됐고SCRIPT/Parse ERROR는없다. 기존전투오디오 ObjectDB 종료경고는잔여다.
- 다음: 사용자5·6성실플레이피드백. 수치는피드백전선제조정하지않는다. 성장부담/수급, iPhone/장기육성은미검증. 신규종·직업·교차계열재료·새선택권은추가하지않았다.


재실행: tools/audit_suite.py --godot PATH --out docs/evolution-six-tests.json. 격리UI/전투장면은 animation/evolution_six_*_review.tscn. 기존 tools/preview.py를사용하거나Godot --write-movie로직접캡처할수있다.
