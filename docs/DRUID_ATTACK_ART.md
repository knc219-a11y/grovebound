# 주인공 연속 공격 원화

2026-10-20. 사용자 피드백: 몸체 크기는 수정됐지만 일반 공격이 단일 강화 자세라 부자연스러움. 일반 공격을 강화 원화에서 분리하고 준비/발동/후속/팔 회수6종의 연속 자세를 새로 제작했다. 원본 대기를 처음/끝에 넣은8셀 시퀀스다. 회복/강화/소생과 기존 보행은 유지한다.

## 에셋과 배율
- 내장 imagegen 사용, 참조 `assets/party-pixel/druid-body-v2.png`, 크기 수정된 `assets/attacks-v2/druid-support.png`. 원본 `assets/attacks-v2/druid-attack-source-v1.png`(1536×1024), 런타임 `druid-attack-v1.png`(896×104,112×104 셀8개).
- `tools/pack_druid_attack.gd -- res://assets/attacks-v2/druid-attack-source-v1.png`로 재생성. alpha0.5 경계/최근접 축소, 여백으로 행 분리, 전체 새 원화 공통 배율. 지팡이를 제외한 원본 몸체60px에 맞춘다. 모든 실제 프레임 몸체60px/동일 발 기준94. 펼친 팔 때문에 전체 bounding box 중심이 이동하지 않도록 발 아래10% 영역을 기준으로 정렬한다. 원본 대기 셀0/7은 동일 픽셀이다. 캐릭터/무기 표시 크기·카메라는 변경하지 않는다.
- 지팡이는 기존 별도 에셋/교체 API 그대로. `animation/druid-attack.json`의 프레임별 손잡이/각도를 몸체 상태와 공유하고 각도는 프레임 사이에서 smoothstep 보간한다. 전체 이미지를 확대/축소하거나 흔드는 방식은 사용하지 않는다. 새 그림 자체가 원본 대기와 완전히 동일한 픽셀 구조는 아니며 미적 최종 승인은 남아 있다.

## 시간과 판정
`animation/druid_attack.gd`: 0.52초 시퀀스, 프레임 시작0/.04/.09/.14/.195/.26/.33/.41초. .14초가 발동 자세이며 이후 손을 거두고 원본 대기로 돌아간다. 기본 공격 대기 시간이 .14초 이하일 때 준비를 먼저 재생하고, 실제 기존 피해 이벤트에서 발동 프레임으로 연결한다. 최초 즉시 공격은 기존 첫 피해를 늦추지 않기 위해 발동부터 보여준다.

주인공 피해6/자동 공격 주기0.85초/사거리250/즉시 판정은 유지한다. 새 준비 때문에 추가 피해나 피해 지연이 생기지 않는다. 준비 중 대상이 없어지면 취소한다. 이동 중에는 기존 보행/기본 지팡이가 우선이며, 명시적 회복·강화·소생을 자동 공격 자세가 끊지 않는다. 메뉴 정지 시 게임 타이머와 함께 멈춘다. 세이브·성장·수집 변경 없음.

## 검증과 캡처
신규 `tools/test_druid_attack.gd`: 실제 update_game 준비 구간 무피해/기존6피해·.85초/발동 프레임/대상 소실 취소,8프레임 경로/6신규+동일 대기/몸체58..60px 상한/발 접지/손잡이/이동·사망·지원 우선. `test_druid_support.gd`, `test_action_events.gd`, `test_skill_visual.gd`, self-test도 PASS. 기존 헤드리스 오디오 정리 ObjectDB 경고는 별도로 남으며 렌더 SCRIPT/Parse ERROR는 없다.

`animation/druid_attack_review.tscn`은 사용자 저장을 격리한 실제 자동 공격6초(검토용 대상만 기절): `docs/druid-attack-gameplay.png`, `.gif`/`.mp4`. 이 장면의 주인공 일반 공격에는 별도 타격음이 연결되지 않아 음향 검토용은 아니다. `animation/druid_attack_pose_review.tscn` → `docs/druid-attack-detail.gif`/`.mp4`: 기존 대기와 연속 공격을3배로 나란히 그린 QA, 실제 게임 카메라 확대가 아니다. 모바일 실기기/사용자 미적 평가는 미검증.

## 생성 프롬프트
Use case: stylized-concept. Asset type: six consecutive animation keyframes for the SAME small adult hooded druid RPG character, BODY ONLY without a staff. Match image1 EXACT character identity, slender adult proportions, hood, dark moss cloak/leather/boots, subdued brown/green palette and crisp low-resolution pixel clusters. Image2 is a secondary style reference; keep the body slender like image1, not bulky. Output ONE transparent PNG sheet exactly THREE equal columns by TWO equal rows, reading order left-right then next row. Fixed three-quarter side view facing RIGHT in all six frames, fixed planted feet at identical x/y, same body scale, head/hood center and top/bottom constant. Only arms, shoulders and cloak folds smoothly change. ALL SIX are sequential distinct poses of ONE continuous magic hand-cast action: frame1 subtle anticipation, free right hand draws inward from relaxed waist, staff-gripping left hand remains near waist; frame2 gathers magic with right elbow bent and palm near chest, left staff hand lifts just slightly; frame3 release, right forearm extends forward palm out at chest height, left hand braced; frame4 soft follow-through, right hand remains forward but drops a little; frame5 retracts right forearm halfway toward chest; frame6 almost relaxed again, right hand lowering toward original idle waist, returning to frame1. The hand gripping a future separate staff must be clearly visible at waist/chest with fingers closed and must not disappear under the cloak. Body stays upright, head unchanged, no stepping or jumping, no squash/stretch or scale change. Draw smooth incremental arm motion, NOT six unrelated gestures. Clear transparent margins/gutters around each whole body; every body fully contained in its cell. No text/numbers/borders, no staff/weapon/magic particles/shadow/background/glow. This will downsample to a 60-pixel-tall visible body.
