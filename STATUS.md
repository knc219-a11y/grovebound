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
4. 사용자의 재개 요청에 따라 모션 연결 1차 개선을 적용했다. 아래 적용 내역과 남은 제한을 확인한다.

## 모션 개선 1차 적용 (2026-10-19)
- 보류 패치를 현행 작은 캐릭터 기준으로 수동 검토·이식했다. 캐릭터 높이·월드·카메라·배경은 변경하지 않았다.
- 이동 중에는 정지형 전신 행동 포즈를 표시하지 않고 거리 기반 보행/빠른 걸음 프레임을 유지한다. 이동 공격 전용 신규 프레임은 아니다. 제자리 공격은 시작 시 방향을 기억한다.
- 동료/적의 공통 이동은 약 0.17초 가속하고 마지막 40px에서 감속한다. 정지 거리 초과를 막으며 좌우 차이가 14px 이하면 방향을 유지한다. 플레이어 직접 조작 속도는 기존 유지. 추격/공격 도달 시간은 이 완충 때문에 달라질 수 있으나 피해·회복량/쿨다운/판정 거리는 변경하지 않았다.
- 피격 위치 반응은 사인 곡선으로 돌아오며, 드루이드/일반 동물 쓰러짐·기상은 0.22초에 걸쳐 기울기를 전환한다. 멧돼지의 기존 0.3초 전환은 유지한다.
- `docs/motion-upgrade-gameplay.gif` / `.mp4`: 실제 Godot 16초 녹화, 8초에 동료 조합 교체하여 전 종 포함. 사용자 세이브와 격리. 수정 전 같은 장면 10초도 로컬 비교용으로 캡처했다.
- 임포트, self-test, pixel_actor/action_events/combat_feedback/art_type/save_repair 검사 PASS, SCRIPT/Parse ERROR 없음. 출발 완충·정지 거리·방향 전환·이동 중 공격·쓰러짐 전환 회귀 검사 추가.
- `docs/wip/motion-upgrade.patch`는 과거 원본으로 보존하며 재적용하지 않는다. 현행 코드가 기준이다.

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

## 다음 대화 시작
- 구체적인 재개 순서·모션 우선순위·완료 기준·새 대화 시작 문구: `docs/NEXT_SESSION.md`.
- 다음은 멧돼지 빠른 추격 보폭과 종별 발 접지 개선. 새 전용 프레임 필요 여부를 검토한다.
