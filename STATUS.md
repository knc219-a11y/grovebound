# Grovebound 작업 인계

## 먼저 읽기
- 공통 규칙: `AGENTS.md`. 사용자의 최신 지시가 우선.
- GitHub: https://github.com/knc219-a11y/grovebound
- Godot 4.7 Standard, 모바일 가로화면. Windows `update-and-play.bat` / 첫 실행 `play.bat`.

## 현재 적용 상태
- 지원형 주인공 + 활동 동료4, 총6마리 준비, 비전투 교체, 중복 허용, 스테이지 자동전투와 사용자 지원 개입.
- 픽셀 캐릭터: 드루이드·멧돼지·담비·여우·거북·사슴·늑대. 드루이드 걷기/달리기, 동물 걷기/빠른 걸음, 각 역할 행동 포즈, 전투 피드백 연결.
- UI: 차분한 석판/청동풍, 초상/체력바/쿨다운, Galmuri Regular/Bold 한국어 폰트와 라이선스 포함.
- 현재 초급 사냥터: `assets/maps/greenwater-beginner-v3.webp`. v2의 선명하고 단순한 도트풍과 길 구도를 유지하면서 배경 소품을 작게 다시 그린 버전. 오래된 폐허와 v1/v2는 보존.
- **캐릭터는 원래 작은 크기**(드루이드72px, 일반 멧돼지48px 등), 기존 카메라/넓은 시야 유지. 840a16b의 캐릭터2배 확대는 사용자가 원한 수정이 아니어서 되돌렸다. 앞으로 비율이 안 맞으면 배경 소품을 조정한다.
- 배경은 단일 이미지이며 소품 충돌/길찾기는 없다. 초급 맵은 평탄하고 열린 이동 구간을 유지한다. 월드2900x1650, 카메라 논리 뷰1440x810.
- 사용자 세이브 정규화/원본 백업/백업 실패 시 자동 덮어쓰기 차단이 구현돼 있다. 녹화 장면은 사용자 세이브와 격리한다.

## 최신 피드백과 진행 순서
1. 사용자는 배경 자체와 선명한 도트풍을 좋아한다.
2. 캐릭터를 크게 해 해결한 비율 수정은 기각. 작은 캐릭터 유지 + 배경 구조물 축소로 수정했다.
3. 최신 인게임 확인: `docs/prop-scale-hud.png`, `docs/prop-scale-gameplay.gif`, `.mp4` (로컬 검토 파일; 원격에 포함되지 않을 수 있음).
4. 비율 피드백을 반영한 뒤 전체 모션 개선을 이어간다. 모션 요청은 취소되지 않았으나 비율 수정 때문에 잠시 보류했다.

## 보류한 모션 작업
- `docs/wip/motion-upgrade.patch`, 설명 `docs/wip/README.md`에 보관. 런타임에는 적용되지 않았다.
- 이동 중 정지형 공격 포즈가 발 동작을 덮는 현상, 동료 출발/정지, 방향 뒤집힘, 피격 이동과 쓰러짐 전환을 개선하려던 작업.
- 패치는2배 캐릭터 시점 기반이므로 현행 크기를 유지하며 수동 재검토할 것. 그대로 적용해 확대를 되살리지 말 것.
- 보류 패치 상태에서는 pixel_actor/action_events/combat_feedback/self-test가 통과했으나 현행에 다시 적용하면 재검증과 실제 GIF/MP4 캡처가 필요하다.

## 검증과 도구
- 현행 비율 수정: Godot 임포트/배경 lossless round-trip/art-type/self-test 통과. 실제 Godot HUD 및6초 전투 녹화 생성. 실기기와 전체 스테이지 완주는 별도 미검증.
- `tools/pack_background.gd -- SOURCE.png res://assets/maps/OUTPUT.webp`: nearest 확대 + lossless RGB 재검증. 원본 해상도 이상 새 디테일은 생기지 않는다.
- `tools/preview.py`: 실제 Godot 캡처 및 GIF/MP4 검증. `animation/ui_hud_review.tscn`, `animation/full_gameplay_preview.tscn` 등 재사용.
- 회귀 검사: `-- --self-test`, `tools/test_art_type.gd`, `test_ui.gd`, `test_pixel_actor.gd`, `test_action_events.gd`, `test_combat_feedback.gd`, `test_save_repair.gd`.
- 로컬 Godot `.tools/linux/Godot_v4.7-stable_linux.x86_64`, Xvfb `.tools/x11/root/usr/bin/Xvfb` (환경에 없으면 재설치 필요).
- 모션/배경 관련 생성 프롬프트와 원본 경로는 개별 `docs/*.md`에 기록. 실험 폴더와 오래된 캡처를 현재 적용품으로 혼동하지 말 것.

## 알려진 제한
- 빠른 추격은 보행 주기 상한 때문에 발 미끄러짐이 남을 수 있다. 현재 행동 프레임은 기존 원화의 변형 기반이며 완전히 새로 그린 해부학적 포즈가 아니다.
- 저장소의 관련 없는 로컬 실험 변경은 보존한다. 새 작업에서 전체 add/reset으로 덮어쓰지 않는다.
