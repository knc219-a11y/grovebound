# 다음 Work 인계 · 2026-10-20 합성·승급 설계

반드시 최신 main에서 AGENTS.md → docs/PROJECT_SETTINGS.md → STATUS.md → 이 문서를 읽는다. 사용자 설정을 새로 확정/변경한 모든 대화에서 PROJECT_SETTINGS를 갱신하고 구현 상태/검증/다음 단계도 함께 기록한다. `python tools/check_handoff.py` 실행 후 범위 파일만 GitHub에 반영하고 ref를 확인한다. 계정 전체 채팅에 자동 적용되었다고 말하지 않는다.

## 최우선: 4→5 완료 이후
- 현재4→5 실제진화/영구선택/복구/9개능력은 구현됐다. docs/EVOLUTION.md와 docs/PROJECT_SETTINGS.md「5·6성 진화 확정」을 읽는다. docs/EVOLUTION_NEXT_WORK.md는 이전 제안 이력이며 이미 승인된 세 묶음을 다시 질문하지 않는다.
- 4성Lv50 주+부→주5성Lv50/상한60. 성공100%/추가비용없음/다른야수종허용/동행6·즐겨찾기보조보호. 주동료ID/종/특성/속성/고유/강화스킬/전체옵션/편성유지, 보조옵션미계승.110→130% 기본성장과역할별3택1 승인수치 적용. 사용자테스트후과하면조정한다.
- 6성Lv60출발/상한70/기본성장110→130%와기존진화능력강화 방향은 확정. **정확한6성강화값은미정이며5→6실행은비활성**이다. 다음작업은 강화수치 합의 후 별도5→6 트랜잭션/검증 구현. 플레이피드백이오면5성밸런스도조정한다.
- 저장v2내 special.version1과별도 special.evolution(version1/state/ability). pending결과와보조소비를한파일에기록후메모리반영, 선택확정도저장성공후반영. 기존4성은재선택하지않으며선택중종료/재접속시진화능력창복구/출발차단. 저장/보호/중복/스냅샷경계를 유지한다.
- 최신Godot4.7.2 전체36/36 PASS: docs/evolution-tests.json. test_evolution/test_evolution_combat와기존4성검사 모두통과. 실제 evolution-materials/confirm/choice/detail.png와 evolution-battle.gif/.mp4 확인.7종두팀12초격리QA이며사람장기성장/실기기검증이아니다. 사용자저장과격리했다.
- 수치: special_companions.gd EVOLUTION_VALUES/EVOLUTION_START/EVOLUTION_PER_LEVEL, 표시문구/검사/PROJECT_SETTINGS를함께수정.기존headless오디오종료ObjectDB경고는별도잔여다.

## 확정 방향
- 현재 주인공은 드루이드 하나. 새 주인공 생성/직업 선택은 아직 추가하지 않는다.
- 드루이드=야수 교감. 미래 다른 직업의 마물/언데드 테이밍을 위해 종 계열·교감 정책을 적 AI/지역 배치와 분리한다. 계약술사/사령술사 명칭은 가칭이며 편성 제한은 미확정이다.
- 작은 캐릭터·넓은 시야/승인 도트풍·독립 지팡이·활동4/준비6·기존 동료/세이브/성장 공식을 보존한다. 다수전 특수 스킬로 몰아잡는 손맛과 소규모 교전/휴식/보스의 리듬을 유지한다.

## 현재 구현
- 최신 A안: 세 지역 일반 보상 대상11을 주력7/나머지 각2로 혼합. 계곡에도 슬라임/해골병, 모든 지역 본선에 야수. 총28/30/30·보상 대상12 유지. 계곡 일반 적 피해80%/약한 무리50%, 보스·타지역·튜토리얼·성장·교감15% 유지. 후방 망령과 돌진 보스의 비활성 복귀 수정 포함. 상세 docs/MIXED_STAGES.md가 아래 이전 캠페인 기록보다 우선한다.
- 직업별 첫 종 정책과 현재 직업 조건 조회·지역별 교감 가능/미확보·도감 출현 지역을 연결했다. 마물/언데드 직업·동료 AI·편성 정책·입문 저장은 아직 구현하지 않았다.
- 계곡(28)→채석장(30)→묘역(30). 마을 동쪽/여정 메뉴의 사냥길 선택, 앞 지역 보스 클리어로 해금, 이전 지역 재방문, 클리어 결과 다음 지역 출발. 권장 레벨1/3/5는 안내만 한다.
- `creature_species.gd` 계열/조건, `campaign.gd` 지역/해금/배치, `enemy_patterns.gd` 새 적 판정, `animation/creature_visual.gd`6종4자세. 새 배경2개/생물6종은 assets/campaign에 적용.
- 슬라임·바위 마물·해골병·망령·수호병은 새 적, 동굴박쥐는 새 드루이드 동료로 실제 교감/편성/육성/기본 공격/급강하/저장까지 연결. 마물/언데드는 현재 교감 기회 없음. 미래 정책 식별자 contractor/necromancer는 플레이 가능한 직업이 아니다.
- 새 지역 본선5/2/8/10+보스1, 선택2+2. 보상 대상12, 약한 추가18은 제압 수만 증가. 기존 일반 보상/성장/교감15%/클리어+10 유지. 보스와 미진입 선택 무리의 조기 교전 차단 유지.
- version1에 cleared_stages/seen_species 추가, 구세이브 unlocked=true는 계곡1만 클리어 처리. JSON 숫자형 정규화, 보상 중복 차단, 기존 동료 재추첨 없음.
- 생물 도감12종 스크롤/계열/조건/기존 동료 찾기, 지역별 HUD/쉼터/미니맵/보스 예고, 새 적의 실제 원형 강타/고정 지면 표적 판정.

## 검증
- 전체29/29 PASS: docs/campaign-2026-10-20-tests.json. test_campaign에서 해금/구세이브/실제 저장 왕복/계열 정책/다른 계열 교감 차단/박쥐 고정 옵션/도감/망령 회피/24프레임 경계 검사.
- 자동4경로: docs/campaign-2026-10-20-journeys.json. 채석장 균형/공격Lv3, 묘역 균형/공격Lv5 모두 본선26제압·보스 제압·마을 귀환. 합성 시작 팀/고정 시드 봇 각1회이며 사람의 난이도/성공률/계곡부터 연속 성장 검증이 아니다.
- 실제 Godot docs/campaign-quarry.gif/.mp4, campaign-graveyard.gif/.mp4, campaign-boss.gif/.mp4. 격리한 생산 중반 무리/묘역 보스 QA이며 전체 완주 영상이 아니다. campaign-selector.png/collection.png는 검토용 상태의 UI. 사용자 저장 미사용.
- 단계별 과거 audit/fix/assault/waves/stage-pacing 결과와 영상은 당시 기록으로 보존. 최신 구현의 결과와 혼동하지 않는다.
- 설정 인계 누락은 tools/check_handoff.py와 GitHub CI 단계에 연결했다. 로컬 검사와 실제 원격 CI 실행 결과는 구분한다.

## 보관 중인 캠페인 후속 작업 (이번 다음 Work 우선순위와 별개)
0. mixed-*.json과 실제 PNG 확인 후 사람의 첫 동료3종 계곡 플레이를 우선 확인. 단독 봇15경로는 본선 완료, 실제 튜토리얼 연속 경로 중 담비는 묘역 실패. 수집과 준비를 포함한 사람 난이도 검증·아이폰은 미완료다. 실패 기록을 성공으로 바꾸어 설명하지 않는다.
1. 사용자 새 배경·신규 적/4자세·공격 예고 체감 피드백. 실제 사람의 계곡→채석장→묘역 연속 성장 경로와 초기1마리 편성 난이도 확인. 수치를 무단 증폭하지 않는다.
2. 박쥐를 포함한 동료 조합 체감, 새 적/보스의 자세·모션 확장. 현재 새 적은4자세의 첫 버전이다.
3. P2-B 밀집 숫자/스킬명, P2-A 주인공 일반 공격음. iPhone 터치/성능/음향·Windows 실기기·장기 밸런스와 headless 오디오 ObjectDB 종료 경고는 미완료.
4. 다른 주인공/마물·언데드 동료 AI와 편성 정책은 후속 승인/설계 단계. 현재 정책표만 보고 이미 구현됐다고 설명하지 않는다.

## 재실행
- python tools/audit_suite.py --godot PATH --out docs/campaign-2026-10-20-tests.json
- GROVE_AUDIT_BASELINE=현재커밋 GODOT --headless --path . --script tools/audit_journey.gd -- --campaign --out=res://docs/campaign-2026-10-20-journeys.json
- tools/preview.py + res://animation/campaign_quarry_review.tscn / campaign_graveyard_review.tscn / campaign_boss_review.tscn. Linux는 Xvfb 필요.
- python tools/check_handoff.py (로컬 스테이징 검사), --base COMMIT_SHA (CI 커밋 차이 검사).

새 Work는 `docs/EVOLUTION.md`와 이 문서 최우선4→5 완료 인계에서 이어간다. 이 문서의 옛 캠페인 검증/다음 작업 목록을 최신 진화 작업보다 먼저 수행하지 않는다.
