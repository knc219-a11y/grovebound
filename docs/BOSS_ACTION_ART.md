# 우두머리 전용 행동 1차

2026-10-19. 기존 멧돼지 원화를 참고해 발구르기3종/돌진3종을 새로 그려 적용했다. 별도 보스 종/능력치/새 패턴은 추가하지 않는다. 기본 멧돼지와 기존 대기·걷기·쓰러짐, 맵/카메라/작은 캐릭터 기준은 유지한다.

## 원화와 재생
- 참조: `assets/boar-pixel-idle.png`, `assets/attacks-v2/boar.png`. 내장 imagegen 사용. 외부 게임 에셋 사용 없음.
- 원본: `assets/attacks-v2/boar-boss-source-v1.png`(1536×1024 RGBA). `tools/pack_boss_art.gd -- res://assets/attacks-v2/boar-boss-source-v1.png`가 `assets/attacks-v2/boar-boss.png`(336×208,112×104 셀3열2행)를 만든다. 원본 발끝이 중간선을 넘어 빈 행을 찾아 분리한다. alpha0.5 경계로 이진화/최근접 축소/공통 배율/발 기준(56,94) 정렬.
- 윗줄: 앞다리 들기/착지/회수. 아랫줄: 머리 낮추기/뻗은 달리기/제동. 돌진 중 압축 자세와 뻗은 자세2개를 이동 거리 기반 rig_phase로 번갈아 표시한다. 완전한 다프레임 달리기 원화 세트는 아니다.
- 착지 몸체 최대48px, 모든 자세 공통 배율이며 앞다리를 들 때만 자연스럽게 높아져 최대64px. 보스의 기존2배 표시(기본 몸체96px)는 그대로다. 새 그림의 착지 실제45px/보스90px이며 프레임별 크기 보정은 하지 않는다. 화면 확대/카메라 변경 없음.
- `animation/boss_action.gd`는 기존 wind/dash/rig_phase를 읽는다. 발구르기 착지 후0.38초(착지0.14/회수0.24), 돌진 종료 후0.32초 제동은 시각 시간이다. 정지 상태에서만 회수를 유지하고 추격 중에는 기존 보행 우선. hp0이면 기존 쓰러짐에 맡긴다. 일반 공격 시트가 보스 회수 뒤 끼어들지 않도록 보스 렌더 경로를 분리했다.
- 앞다리를 드는 동안만 체력바 머리 공간을96→128px로 계산해 얼굴과 겹치지 않게 한다. 본체/물리 영역을 확대하는 처리는 아니다.

## 판정·검증
발구르기 예고1.15초/반경130/피해28/CD2.4초, 돌진 예고1.25초/거리340/속도850/최대0.48초/반경48/피해35/종료CD2.8초는 유지한다. 회수 중 새 이동·입력 잠금/무적/추가 공격을 넣지 않는다. 기존 광역 원/방향 예고/지면 충격 효과음 유지.

`tools/test_boss_action.gd`는6종 원화 경계/고유성/기본 높이, 실제 보스 패턴 교대/예고/기존 피해/쓸기 판정1회/회수/보행·사망 우선을 검사한다. 기존 공격 타이밍/스킬 검사 및 self-test PASS. 헤드리스 종료 시 기존 오디오 ObjectDB 경고가 남으며 실기기/장기 완주/미적 승인은 미검증이다.

실제 게임 `animation/boss_action_review.tscn`: 사용자 세이브 격리, 실제 AI/전투/이동을 실행하고 첫 예고 때 왼쪽으로 이동한다. `docs/boss-action-gameplay.mp4`12초(소리 포함), `.png`, 짧은 무음 `.gif`. 제작 확대 검토 `animation/boss_pose_review.tscn` → `docs/boss-action-detail.gif`/`.mp4`:48px 기본 원화를3배로 그리는 QA 장면이며 게임 카메라는 아니다. QA 장면은 타이머를 재현하므로 실제 판정은 게임 영상과 자동 검사에서 확인한다.

## 생성 프롬프트
Use case: stylized-concept. Asset type: production pixel art RPG boar boss action pose sheet, actual transparent PNG. Input image 1 is the exact existing boar identity/palette reference, input 2 is existing attack style reference. Create ONE sheet, exactly 3 equal columns x 2 equal rows, each cell contains ONE complete identical brown wild boar facing RIGHT, same scale, fixed camera three-quarter side view. Crisp low-resolution pixel clusters, dark brown/gray fur, cream tusks, no accessories, no magical growth, retain original silhouette/face proportions and dorsal bristles. ROW1 STOMP sequence: col1 raising BOTH front legs with rear hooves firmly grounded, torso angled upward a little; col2 forcefully stamping both front hooves onto ground, head/tusks lower, all hooves on same baseline; col3 settling/recovering, head higher, legs planted. ROW2 CHARGE sequence: col1 crouched front legs and head lowered with tusks pointing forward, hind legs digging in; col2 dynamic forward gallop, all four legs bent in clearly running stride, low head and forward tusks, NO speed trails; col3 braking with front legs braced forward and hind legs tucked. Same horizontal center and foot baseline in every cell; 20% clear transparent margins inside each cell, wide blank transparent gutters between ALL cells. These are different newly drawn physical poses, not rotating/stretching one sprite. Full bodies never clipped. Flat original game pixel sprite style, limited muted brown palette, top-left light, hard pixels, no soft painting, no text/numbers/grid/borders, no shadows/dust/effects/background.

다음은 첫 사냥터 실제 완주 검토: 일반전→선택 동선→쉼터→보스→귀환의 길이, 동료 역할/지원 타이밍, 전투 텍스트·소리 중첩. 사용자의 피드백 없이 수집/성장/보상을 임의 조정하지 않는다.
