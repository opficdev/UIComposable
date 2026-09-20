# UIComposable Agent Instructions

## Policy Bootstrap

이 저장소의 AI 작업 정책은 [UIComposable Agent Policy](https://app.notion.com/p/3e0b88a8aa548135b808d98afc549847)에 있다. Repository의 구현, 테스트, package 설정, CI/CD와 GitHub Template은 현재 구현 사실의 기준이다.

작업 전에는 Policy Index에서 `Active` 상태인 정책만 확인한다.

1. 모든 작업에서 `General`과 `UIComposable`을 읽는다.
2. 현재 요청과 일치하는 정책을 추가로 읽는다.
3. Policy Index에 없는 정책, `Inactive` 정책, 관련 없는 Decision Memory와 Specs는 읽지 않는다.
4. 필요한 Notion 정책을 불러올 수 없으면 작업을 멈추고 그 사실을 보고한다.

정책 내용과 Agent Contract는 Notion에서만 관리한다. 이 파일에는 정책을 중복해서 기록하지 않는다.
