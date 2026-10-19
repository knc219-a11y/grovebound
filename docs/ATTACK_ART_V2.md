# 멧돼지·늑대 공격 원화 v2

## 제작 기준
- 원본 `assets/boar-pixel-idle.png`, `assets/party-pixel/wolf.png`를 직접 참조해 built-in image generation으로 준비/타격/회수 3포즈를 제작했다. 기존 대기/이동 원본은 보존한다.
- 최종 생성 원본: `assets/attacks-v2/source-v2.png`. 실행 시트: `boar.png`, `wolf.png`. 112×104 셀 6개: 기존 대기→준비→타격→타격 유지→회수→기존 대기. 6개 모두 새 원화라는 뜻은 아니며 새 포즈는 종별3개다.
- `tools/pack_attack_art.gd -- res://assets/attacks-v2/source-v2.png`: 3×2 시트 분리, 낮은 알파 경계 제거/이진화, nearest 축소, 종별 공통 배율과 발 기준 정렬. 최대 높이48px이며 게임 카메라/캐릭터 기준 높이는 바꾸지 않는다.

## 생성 프롬프트 요약
1. Reference boar and wolf, muted brown/gray crisp pixel art, face RIGHT, exact 3 columns ×2 rows, genuine transparent background. Row1 boar; row2 wolf. Anticipation: crouch and pull back. Impact: shoulder/tusk thrust / extended open-jaw bite. Recovery: replant feet and retract head. Consistent anatomy, markings, size and baseline, no text/grid/VFX/background.
2. Remove all background, halo, glow and drop shadow; keep only six crisp animal silhouettes and preserve grid/poses/placement. 최종 소스의 약한 알파 경계는 패킹 시 이진화했다.

## 연동과 제한
- 동료 기본 공격은 총0.42초 표시 중0.14초에 판정한다. 기존1.2초 공격 주기와 피해량 유지. 준비 중 사망/대상 소멸/사거리 이탈 시 피해 취소. 이동형 공격 신규 시트는 아니며 이동하면 기존 보행을 우선한다.
- 일반 적은 기존0.65초 예고 중 준비 자세를 사용하고, 원래 판정 순간에 타격 프레임부터 표시한다. 보스는 기존 패턴/포즈를 유지한다. 즉시 피해 스킬은 타격 프레임부터 시작한다.
- 실제 타격에만 짧은 밝은 중심과 종별 방향성 파편을 추가했다. 전체 화면 흔들림/히트스톱/새 공격력/효과음은 추가하지 않았다.
- 던전시스터즈 공식 Google Play 화면의 밝은 접촉 지점과 방향성 효과를 시각 참고로 삼았다. 원본 에셋은 복사/추출하지 않았다. https://play.google.com/store/apps/details?id=com.lobstargames.dungeon.idle.rpg
- 플레이 영상 링크 https://youtu.be/u1Uey_494Cg 는 찾았으나 도구에서 재생되지 않아 프레임별 영상 분석은 수행하지 않았다.
- 실제 재현: `animation/attack_v2_review.tscn`, 제작용 확대: `animation/full_motion_review.tscn`. 캡처는 사용자 저장을 읽거나 쓰지 않는다. 최종 사용자 미적 평가/모바일 실기기/장기 난이도 영향은 미검증이다.
