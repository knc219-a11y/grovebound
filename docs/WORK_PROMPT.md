# Grovebound 표준 Work 프롬프트

아래에서 '이번 작업'만 바꿔 새 Work에 전달한다. 상세 규칙은 저장소 문서를 기준으로 하며 이 텍스트는 자동 실행 설정이 아니다.

```text
Grovebound 최신 main에서 다음 작업을 진행해줘.
저장소: https://github.com/knc219-a11y/grovebound

이번 작업:
[추가·개선·수정할 내용]

원격 최신 main과 미완료 PR·진행 작업을 확인하고 AGENTS.md,
docs/PROJECT_SETTINGS.md, STATUS.md, docs/NEXT_SESSION.md,
docs/MULTI_AGENT_DEVELOPMENT.md, docs/agents/GAME_DESIGNER.md와 관련 계약·소스를 읽어줘.
확정 설정·사용자 저장/진행도·기존 미커밋 변경을 보존해줘.

총괄은 기획 에이전트의 사전 적합성 검토와 필요한 웹 사례 조사를 받아 범위를 확정하고,
중요한 미정 기획·밸런스 변경만 사용자와 합의해줘.
같은 기준 SHA의 독립 worktree·브랜치와 비중복 파일 소유권으로 개발을 분배하고
가능한 작업은 실제 병렬 실행해줘. 실행 미지원이면 순차 대체와 한계를 밝혀줘.
개발 후 작성자와 다른 QA의 독립 검증, 기획 사후 검토, 총괄 통합 검증을 수행해줘.
공통 규칙의 자동 회귀·저장 호환·실제 Godot 실행·UI 인게임 캡처를 적용하고
미실행 검증은 정확히 밝혀줘.

상태·인수인계 문서와 변경된 확정 설정을 갱신하고 브랜치와 PR을 생성해줘.
이번 요청은 필수 검증·CI 통과 후 main 병합까지 승인하며 원격 main SHA를 확인해줘.
해결하지 못한 결함이나 검증 실패가 있으면 병합하지 말고 PR과 원인을 보고해줘.
```
