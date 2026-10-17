# 3D 보행 → 2D 프레임 실험

이 폴더는 제작 방식 검토용이며 게임의 기본 멧돼지 렌더러를 교체하지 않습니다. 현재 외형은 몸통·머리·다리를 부드럽게 합친 암시적 표면과 연속 스킨 변형으로 구성합니다. 이전 도형 조립 버전은 `boar_model_blockout.gd`와 `boar3d-blockout-sheet.png`에 보존했습니다. 승인된 2D 원화의 최종 그림체를 재현한 모델이 아닙니다. 추가 이미지 생성 API 없이 프레임은 Godot 4.7에서 다시 출력합니다. 표면을 다시 만드는 Python 도구의 의존성은 아래에 정리했습니다.

## 구현

- `boar_model.gd`: 연결된 몸통·목·다리 표면, 곡선 귀와 엄니, 털 색 변화. 원화와 비율을 비교하며 다듬는 실험입니다.
- 각 다리는 두 링크의 관절 위치를 해석적으로 계산합니다. 표면은 몸통과 각 다리의 상/하부 관절을 따라 연속적으로 변형됩니다. 수작업 Skeleton3D 리깅 모델은 아닙니다.
- 걷기 한 주기 0.8초, 이동 거리 0.8 단위, 지지 구간 64%.
- 발이 지지 중일 때 몸통의 전진과 발의 상대 후진이 상쇄되어 월드 위치가 유지됩니다.
- 복귀 구간은 Hermite 보간과 제곱 사인 높이로 이륙/착지에서 속도를 연결합니다.
- 같은 카메라·모델·조명으로 16프레임을 출력해 프레임별 외형 생성 차이를 피합니다.

## 재사용하는 출력 과정

Godot에서 `export_frames.tscn`을 F6으로 실행하면 `assets/boar3d-walk-sheet.png`와 `frames.json`을 다시 만듭니다. 그래픽 화면이 있는 환경에서 실행해야 하며 headless 모드로는 이미지를 만들 수 없습니다.

```sh
Godot --path . res://experiments/boar3d/export_frames.tscn
python tools/preview.py --godot Godot --scene res://experiments/boar3d/review.tscn --out docs/boar3d-comparison --seconds 4.8 --width 1200 --gif-width 960 --gif-fps 20 --gif-seconds 3.2
```

Windows에서는 `Godot`을 `.tools/Godot_v4.7-stable_win64_console.exe`로 바꾸면 됩니다. Python 도구에는 FFmpeg도 필요합니다.

출력은 512×384 프레임 16장, 4×4 시트, 투명 PNG입니다. 전체 주기의 공통 크롭과 같은 지면 기준점을 사용해 프레임별 확대/축소를 하지 않습니다. 게임에 적용할 경우에는 2D 텍스처와 프레임 재생만 필요하며 실시간 3D 모델을 함께 실행할 필요가 없습니다.

## 표면을 다시 만드는 도구

```sh
python -m pip install -r tools/requirements-3d.txt
python tools/build_boar_surface.py
```

`build_boar_surface.py`는 타원체/테이퍼 캡슐의 부드러운 합집합을 등가면 메시로 만들고, 털 색과 최대 4개 관절 가중치를 저장합니다. 결과 `boar_surface.json.gz`는 Godot에서 읽습니다. 메시 생성에만 NumPy/scikit-image가 필요하고, 이미 만들어진 표면의 렌더/프레임 출력에는 Godot만 필요합니다. 결정된 난수 시드를 써서 다시 생성할 수 있습니다.

현재 표면은 약 4,400정점입니다. 모델의 CPU 스킨 변형은 원화 프레임 출력용이며 모바일 실시간 3D 성능을 목표로 최적화한 구현은 아닙니다.

`style_review.tscn`은 확정 원화 / 이전 도형 / 연결 표면 버전을 나란히 재생합니다. `docs/boar3d-style.png`, `.gif`, `.mp4`로 출력했습니다.

## 검증과 한계

`test_kinematics.gd`는 지지 발의 월드 위치 유지, 전 주기의 두 뼈 길이 유지, 반복 주기, 투명 출력 시트 크기를 확인합니다. Linux CI에서도 실행합니다. 실제 3D 렌더와 PNG 출력, 비교 녹화는 로컬 Godot 4.7 GL Compatibility/Xvfb에서 검토했습니다.

몸통·목·다리는 연결된 표면이지만, 원화 특유의 털 끝 실루엣과 손으로 그린 명암을 그대로 재현한 것은 아닙니다. 닫힌 표면과 정규화된 관절 가중치를 추가로 검사합니다. 지지 구간의 계산이 정확하다는 것만으로 체중 이동, 표정, 갈기/귀의 후속 동작까지 자연스러워지는 것은 아닙니다. 모바일 기기 성능/실시간 3D 렌더는 검증하지 않았습니다.

참고: Godot 공식 문서의 [SubViewport](https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html)와 [StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html).
