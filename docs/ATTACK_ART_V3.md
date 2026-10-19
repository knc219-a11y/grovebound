# 담비·여우 공격/시전 원화

- 기존 `assets/party-pixel/marten.png`, `fox.png`를 직접 참조해 built-in image generation으로 종별 준비·타격/방출·회수3포즈를 제작했다. 생성 원본은 `assets/attacks-v2/marten-fox-source-v1.png`, 실행 시트는 같은 폴더의 `marten.png`, `fox.png`다. 기존 대기 두 칸과 새 포즈를 조합한6셀 시트이며 타격 포즈는2칸 유지한다.
- 프롬프트: 1536×1024, strict3columns×2rows, transparent background, no text/grid/VFX/shadow; reference-identical right-facing3/4side pixel art. Row1 long low brown marten with short legs: crouch/retract forepaw→low forward stretch and downward forepaw swipe→replant. Row2 orange fox with white chest/tailtip and black legs: gather with lowered head→lift muzzle and tail to release spell→recover. Preserve markings, silhouette, muted palette and consistent scale/baseline.
- 패킹: `tools/pack_attack_art.gd -- res://assets/attacks-v2/marten-fox-source-v1.png marten fox`. 같은 도구가 기존 멧돼지·늑대 기본 호출도 지원한다. nearest축소/알파 이진화/발 기준 정렬, 담비32px/여우40px 최대 원화 높이. 기존 카메라와 표시 배율은 유지한다.
- 동료 기본 공격은0.14초 준비 후1회 피해/기존 피격 효과를 적용한다. 담비0.85초/여우1.2초 공격 주기, 사거리/피해/옵션/스킬 쿨다운은 유지한다. 여우는 기존 즉시 기운탄 접촉 효과를 타격 순간에 시작하며 비행형 투사체 판정을 새로 추가하지 않았다. 즉시 스킬은 타격 포즈에서 시작한다.
- 적의 기존0.65초 예고/피해 시점은 유지하고 예고 중 준비, 피해 적용 뒤 타격/회수 포즈를 표시한다. 이동 중에는 기존 보행을 우선한다.
- 실제 재현 `animation/attack_v3_review.tscn`: 두 종 기본 공격→여우 스킬→담비 스킬. `docs/attack-v3-gameplay.gif`/`.mp4` 및 `.png`, 제작 판독용 `attack-v3-detail.gif`/`.mp4`. 저장 격리. 이미지 생성 시안과 실제 게임 녹화를 구분한다.
- `tools/test_attack_timing.gd`는4종의 준비 중 무피해/타격1회/사망·원격 차단/원화4종류 이상·경계·종별 높이를 검사한다. 미적 최종 승인과 모바일 실기기 성능은 사용자 확인 대상이다.
