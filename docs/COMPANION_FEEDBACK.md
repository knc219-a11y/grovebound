# 동료 플레이 피드백 개선

## 현재 동작
- 육성 화면에 들어가면 편성용 선택과 최근 클릭을 해제한다. 필터·스크롤은 유지한다. 다른 왼쪽 동료를 누르면 선택만 바뀐다.
- 왼쪽 같은 동료를450ms 안에 두 번 누르면 동행/보관 전환, 오른쪽 같은 슬롯·동료를 두 번 누르면 동행 해제한다. 다른 표면/동료/슬롯, 필터 변경과 배치 완료 뒤에는 클릭을 이어 세지 않는다. 탐험 중 추가/해제는 막고 기존 비전투 슬롯 교체는 유지한다. 동행6이 가득 차면 안내하며 기존 슬롯을 교체한다. 저장 실패 시 편성 무변경.
- 새4→5만Lv1·XP0,상한60. 기본능력은4성50의110→130% 선형이다. special.evolution.growth_version=2가 새곡선을 구별하고 선택/왕복 때 유지한다. 기존5성 레벨/XP/능력/투자는 구곡선 그대로,6성 조건과Lv60→70은 그대로다. 이전 버전으로 새표식 세이브를 내려 저장하지 않는다.
- 바람은 이동+8%/기본공격속도+10%(행동간격÷1.1), 속성CDR없음. 사슴은 기본회복 주기에 적용한다. 물/선택형 대기감소는 유지한다.
- 진화 재료와 최종확인에 초상화·#ID·특성·속성/고유/진화능력·옵션·편성/잠금 상태가 표시된다. 최종 소비 버튼에도#ID가 있다.
- 특수개체는 불꽃파편/물파문/대지조각/바람곡선 오라와 타격 잔광으로 구분한다. 범위형은 실제 여우폭발180×반경배율/사슴회복350×반경배율/박쥐충격파100px를 표시한다. 실제범위 확대 없음.
- 마물/언데드의 기존 일반공격을 예고→타격궤적/물기/광선으로 구분한다. 추가공격·적피해·빈도변경 없음. 거북 도발방향·방어/아군보호·실제경감피해를 표시한다. 특정 역할을 필수편성으로 강제하지 않는다.
- 동료관리 하단의 앞/뒤/둘러싸기는 주인공 마지막 이동방향 기준 집결진형이다. 앞에서 거북/멧돼지가 전열을 우선한다. 전투시에는 기존 대상/사거리/도발/추적을 유지한다. 전투중 변경불가. 진형만 원자저장하고 마지막이동방향은 저장하지 않는다. 구세이브/잘못된값은둘러싸기.

## 재현과 증거
```sh
python tools/audit_suite.py --godot /path/to/Godot --out docs/companion-feedback-tests.json
Godot --headless --path . --script res://tools/test_feedback_growth.gd
Godot --headless --path . --script res://tools/test_feedback_qa.gd
python tools/check_handoff.py
GROVE_FEEDBACK_SCREEN=materials python tools/preview.py --godot /path/to/Godot --scene res://animation/companion_feedback_review.tscn --mode still --out docs/companion-feedback-materials
GROVE_FEEDBACK_SCREEN=combat python tools/preview.py --godot /path/to/Godot --scene res://animation/companion_feedback_review.tscn --seconds 5 --fps 30 --out docs/companion-feedback-combat
```
- 사용자 저장을 읽고 쓰지 않는 합성 fixture다. GUI캡처는 실제 Godot4.7 렌더이며 생성시안이 아니다. 정적상태 roster/materials/confirm/front/rear/surround 6PNG, 실제전투5초 GIF/MP4.
- 독립 집중QA: companion-feedback-qa.md/json. 기획: design-reviews/companion-feedback.md. 통합/한계: handoffs/companion-feedback.md.
- 자동검사는 사람 재미·모바일터치·장기5성육성시간을 판정하지 않는다. 탱커의 전략적가치는 실제 편성비교 플레이가 필요하다. 일부 기존 ObjectDB종료경고가 남는다.
