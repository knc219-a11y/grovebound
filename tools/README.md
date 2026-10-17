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
