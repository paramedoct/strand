# 에이전트 공통 지침

## 문서 지침
- 영문 용어 뒤에 한국어 조사나 접미사를 직접 붙이지 마라
- 코드 블록에는 가급적 영어만 사용하라
- 자연스러운 한국어 표현이 있으면 영문 용어보다 우선하라

## 형상 지침
- 논리적 변경 하나마다 작고 의미 있는 커밋을 만들어라
- 소문자 구글 스타일 제목을 사용하라: `add: ...`, `fix: ...`, `refactor: ...`
- 자세한 설명이 필요하지 않으면 본문 없이 제목만 작성하라
- 제목이 광범위하게 느껴지면 커밋을 나누거나 범위를 좁혀라
- 마지막 커밋의 메시지만 고칠 때는 푸시 전에 수정 커밋으로 덮어써라

## 언어별 지침

### Bash
- 버전: `bash 3.2`
- 명령 파일은 사용자가 직접 실행하는 스크립트로 정의한다
- 명령 파일은 저장소 루트 디렉터리에 배치하라
- 명령 파일은 확장자 없이 소문자 단일 단어로 명명하라
- 명령 파일에는 큰 논리적 흐름만 남겨라 
- 모듈 파일은 도메인 로직이 구현된 스크립트로 정의한다
- 모듈 파일은 다음 디렉터리에 배치하라: `utils`
- 모듈 파일은 다음 형식으로 명명하라: `module` 
- 모듈 함수는 다음 형식으로 명명하라: `module_action()`
- 결과는 표준 출력으로 내보내라
- 진단은 표준 오류로 내보내라
- 다음 실행 파일 형태를 기준으로 삼아라

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "$0 <target>" >&2
  exit 1
}

# shellcheck source=/dev/null
source "$ROOT_DIR/utils/source.sh"
source_modules \
  utils/profile.sh \
  utils/target.sh

main() {
  local target
  [ "$#" -eq 1 ] || usage
  target=$1
  profile_prepare
  target_run "$target"
}

main "$@"
```
