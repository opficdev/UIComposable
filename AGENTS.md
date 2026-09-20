# UIComposable Agent Instructions

## Policy Bootstrap

UIComposable의 AI 정책과 설계 판단은 Notion의 `UIComposable Agent Policy`에서 관리한다. 작업을 시작하기 전에 Policy Index를 확인하고 현재 요청에 필요한 정책만 읽는다.

| 작업 | 필요한 정책 |
| --- | --- |
| 모든 작업 | General |
| Public API, ownership, lifecycle, Swift Concurrency, package 또는 dependency boundary 변경 | Architecture |
| Issue, Pull Request, Git, CI, Release, 문서 또는 검증 | Project Workflows |
| 사용자가 SDD를 명시적으로 요청 | SDD Workflow |
| 과거 설계 판단이 현재 요청에 직접 필요 | Decisions |

Repository는 구현, 테스트, package 설정, CI/CD와 GitHub Template의 기준이다. Notion은 AI 정책, Agent Contract, Workflow와 설계 판단의 기준이다. 같은 정책을 두 곳에 중복해서 기록하지 않는다.

## Default Workflow

기본 작업은 현재 문맥을 유지하는 Primary Agent가 수행한다.

1. 필요한 정책과 파일만 확인한다.
2. 요청 범위 안에서 구현한다.
3. 변경에 필요한 build, test 또는 lint를 실행한다.
4. 검증 결과와 남은 제약을 보고한다.

일반적인 GitHub 조회, CI 분석, Issue 또는 Pull Request 작성은 Primary Agent가 수행한다. 단순 정보 조회나 문서 작성을 위해 Sub-agent를 사용하지 않는다.

## Conditional Agents

`Designer`는 사용자가 SDD 또는 설계 승인 절차를 명시했을 때 사용한다. `Architecture Watcher`는 Public API, ownership, lifecycle, coordinator, delegate, Swift Concurrency, package target 또는 dependency direction 변경에서만 사용한다. `Code Reviewer`는 사용자가 review를 요청하거나 SDD의 최종 review가 필요할 때 사용한다. `Verification Runner`는 release 전 또는 독립 검증이 필요한 경우에만 사용한다.

## SDD

SDD는 사용자가 명시적으로 요청한 경우에만 활성화한다. 일반 구현에서 Spec 작성이나 승인 단계를 추가하지 않는다.
