# 반복 검토 도구

`preview.py`는 Python 표준 라이브러리만 사용하는 정지 이미지/영상 출력 도구입니다. Godot과 FFmpeg가 필요합니다. Windows에서는 Python 3와 FFmpeg를 PATH에 두고 프로젝트 폴더에서 실행합니다.

```sh
python tools/preview.py --godot .tools/Godot_v4.7-stable_win64_console.exe --scene res://animation/boar_preview.tscn --out docs/boar-current
```

Godot 임포트 → 지정 장면 고정 FPS 녹화 → 오류 검사 → GIF/MP4 인코딩 → MP4 디코딩 검사를 수행합니다. Godot이 오류를 출력하면서 종료 코드 0을 반환하는 경우도 실패로 판정합니다. 중간 AVI는 임시 폴더에서 정리합니다.

- `--mode still`: PNG 정지 장면 출력.
- `--seconds 6 --fps 30 --gif-fps 12 --width 768`: 출력 길이/크기 조절.
- `--skip-import`: 리소스 임포트가 이미 끝난 반복 검토에서만 사용.
- Linux에서는 그래픽 세션 또는 Xvfb가 필요합니다. headless 모드는 화면 녹화를 지원하지 않습니다.
- 전용 검토 장면을 지정하세요. 실제 게임 장면을 녹화하면 해당 장면의 저장/진행 로직도 실행됩니다.
- 현재 검증 환경은 Linux + Godot 4.7 + Xvfb + FFmpeg입니다. Windows Python 실행은 별도 검증 전입니다.

## 스프라이트 시트 분석

```sh
.tools/Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tools/inspect_sprite_sheet.gd -- --layout=components --source=res://assets/boar-walk-sheet.png --out=res://animation/boar_walk_frames.json --columns=4 --rows=2
```

`grid` 모드는 각 셀의 불투명 픽셀 영역을 찾고 격자 경계에 닿으면 실패합니다. `components` 모드는 연결된 큰 윤곽을 찾아 행/열 순서로 정렬하므로 그림이 셀 경계를 조금 벗어나도 잘리지 않습니다. 컴포넌트 개수가 예상과 다르거나 전체 시트 경계에 닿거나 프레임 높이 편차가 20%를 넘으면 실패합니다. 그림의 픽셀은 수정하지 않고 JSON 메타데이터만 만듭니다. 잘못된 해부학이나 프레임 순서까지 자동 판정하지는 않으므로 시각 검토가 필요합니다.

`preview.py --gif-width 768 --gif-seconds 4.1`로 MP4는 전체 길이를 유지하면서 GIF 미리보기만 짧고 작게 만들 수 있습니다.
