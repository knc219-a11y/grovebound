# 4→5성 진화 구현과 인계

2026-10-20. 기준 main:08c82fed68e6ed87e249e286e05e8915e2156b18. 사용자 승인값은 docs/PROJECT_SETTINGS.md「5·6성 진화 확정」이 기준이다. EVOLUTION_NEXT_WORK.md는 당시 제안 기록이며 현재 확정/구현은 이 문서와 최신STATUS를 우선한다.

## 사용 흐름

마을 → 동료 관리 → 4성Lv50 동료 육성 → **5성 진화** → 보조 동료 선택 → 소비 대상ID/이름 확인 → 진화 → 역할별 능력3택1 → 최종확정. 선택중 종료하면 같은 동료와 옵션을 복구하고 출발 시 선택창으로 안내한다. 주 동료의 동행/즐겨찾기는 유지되며 보조만 소비한다. 5성Lv50부터60까지 기존 육성/전투XP를 사용한다.

5성Lv60의6성 진화 버튼은 준비중/비활성이다. 6성Lv60 출발·상한70·기본능력110→130%와 기존 진화능력 강화 방향은 승인됐지만, 강화값/실제5→6 실행은 후속이다.

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

다음: 사용자 플레이피드백으로5성 수치 조정 여부 확인,6성 강화수치 합의 후5→6 별도 구현. 신규특수종/확률/직업/다계열동료AI/지역과 성장재료 수급은 변경하지 않았다.
