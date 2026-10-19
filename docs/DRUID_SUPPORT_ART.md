# 드루이드 회복·강화·소생 원화

## 크기 수정 (2026-10-20)
- 사용자 피드백: 자동 공격 때 주인공이 커졌다 작아졌다 함. 원인은72px 전체 스프라이트(지팡이 포함)를 몸체만의 기준으로 잘못 사용한 것. 원본 몸체 파일은48×72지만 불투명 몸체 높이는60px이다. 새 서 있는 몸체72px와 원본60px가 공격/회수 때 교차했다.
- 패킹 배율을 원본 몸체 alpha bounds 높이60px에서 계산하고 중심도 원본 불투명 영역에 맞췄다. 원본 대기 프레임/보행/카메라/표시 높이72px는 그대로다. 모든 서 있는 공격·회복·강화·대기 몸체는60px, 무릎 꿇기는 같은 배율에서 자연스럽게 낮아진다. 지팡이는 원래 크기를 유지하며 손잡이 위치/무릎 자세 각도만 보정한다.
- `test_druid_support.gd`는 실제 자동 공격 경로, 전 프레임의 원본 몸체 높이/중심, 지원/소생 수치와 지팡이 접지를 검사한다. PASS. 실제 자동 공격 반복 `animation/druid_scale_review.tscn` → `docs/druid-scale-gameplay.gif`/`.mp4`, 지원 자세 제작 검토 `docs/druid-scale-detail.gif`/`.mp4`. 저장 격리. 아래72px 패킹과 이전 캡처는 수정 전 기록이다.

- 기존 몸체 `assets/party-pixel/druid-body-v2.png`와 전체 모습 `druid.png`를 직접 참조해 built-in image generation으로3자세를 제작했다. 생성 원본 `assets/attacks-v2/druid-source-v1.png`, 실행 몸체 `druid-support.png`. 지팡이는 원래 독립 `druid-staff-v2.png`를 그대로 사용한다.
- 프롬프트: transparent3equalcolumns/one-row fullbodyatlas, exact adult hooded moss-green druid, dark cloak/leather/boots, crisp small reference pixelstyle, faceRIGHT3/4side. Heal: freehand forward palmout; buff: freehand raised palmup; revive: kneel low, freehand downwardforward. Staff-grippinghand stays close to chest/waist. No staff/weapons/VFX/props/shadows/background/text in body art. Preserve body proportions/palette, kneeling naturally shorter.
- `tools/pack_druid_support.gd -- res://assets/attacks-v2/druid-source-v1.png`: split3columns, binary alpha, common scale from original visible body60px, ground94 within112×104 cells. Each action uses6cells: heal/buff holdnewpose4cells then originalidle2cells; revive holdsnewkneelingpose through channel. Three new key poses, not18 separately drawn frames.
- `animation/druid-support.json` stores per-action hand anchors/weapon angles. `druid_pose.gd` shares pose state between body and weapon. Weapon rotates around its grip(32,36) in the original texture and mounts at the current hand; idle/moving/recovery uses the original grip. Death tilt now applies to weapon and body together.
- New support poses render the rigid staff in front of the cloak for visibility. Existing idle/walk keep their previous layer order. Weapon visual swapping API remains independent from stats. No equipment system was added.
- Heal/buff apply immediately as before; dedicated pose lasts0.6s and returns to original idle. Walking takes priority. Revive pose follows actual held channel and exits immediately when interrupted or after3s. Q55HP/8s, E14s, 3s/30% revive unchanged.
- Actual isolated gameplay `animation/druid_support_review.tscn` calls Q/E/heldrevive; `docs/druid-support-gameplay.png`, `.gif`/`.mp4`. Enlarged QA `animation/druid_pose_review.tscn`, `druid-support-detail.gif`/`.mp4` is3× for grip inspection, not a game camera change.
- `tools/test_druid_support.gd`: body/weapon state selection, walk/recovery grip reset, real heal/buff/revive/interrupt rules, native72px bounds. User art approval/mobile performance remain unverified.
