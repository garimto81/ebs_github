---
name: gemma
description: Local Gemma 4 delegation — 텍스트 처리, RAG 검색, 단순 작업 오프로드. Ollama (localhost:11434) OpenAI-compatible API.
version: 1.0.0
triggers:
  keywords:
    - "/gemma"
    - "gemma"
    - "로컬 모델"
    - "ollama"
auto_trigger: true
---

# /gemma - Local Gemma 4 Delegation

## 서브커맨드

| 커맨드 | 설명 |
|--------|------|
| `/gemma <prompt>` | 직접 프롬프트 전달 |
| `/gemma summarize <text\|file>` | 요약 |
| `/gemma translate <text> --to <lang>` | 번역 |
| `/gemma analyze <text\|file>` | 분석/인사이트 추출 |
| `/gemma rag <query>` | RAG 파이프라인 (Qdrant 검색 + Gemma 4 생성) |
| `/gemma status` | Ollama 상태, 모델 로드 여부, 응답 시간 |

## 실행 워크플로우

### Step 0: Health Check

GemmaClient (`.claude/ml/gemma_client.py`) 사용.

1. `GemmaClient.is_available()` 호출
2. 실패 시: "Ollama 미연결 — Claude fallback" 메시지 출력 후 일반 Claude 응답으로 진행
3. 성공 시: Step 1 진행

### Step 1: 서브커맨드 파싱

args에서 서브커맨드 추출:
- 없음 → 직접 프롬프트 모드
- `summarize` → 요약 모드
- `translate` → 번역 모드 (--to 파라미터 파싱)
- `analyze` → 분석 모드
- `rag` → RAG 모드
- `status` → 상태 확인 모드

### Step 2: 프롬프트 구성

**직접 프롬프트**: system_prompt 없이 사용자 입력 그대로 전달

**summarize**: system_prompt: "다음 텍스트를 핵심만 간결하게 요약하라. 불릿 포인트 형식. 한국어 응답."

**translate**: system_prompt: "다음 텍스트를 {target_lang}로 자연스럽게 번역하라. 원문의 뉘앙스와 맥락을 유지."
기본 target_lang: "영어" (--to 미지정 시)

**analyze**: system_prompt: "다음 텍스트를 분석하여 핵심 인사이트, 패턴, 주요 포인트를 추출하라. 구조화된 형식으로 응답."

**rag**:
1. Bash로 RAG 검색 실행:
   ```bash
   cd /c/claude/vllm && python -c "
   from scripts.rag_pipeline import FAQPipeline
   p = FAQPipeline(vllm_url='http://localhost:11434', model_name='gemma4')
   result = p.query('{query}')
   print(result['answer'])
   "
   ```
2. 또는 GemmaClient에 검색 컨텍스트를 system_prompt로 전달

**status**:
1. `GemmaClient.is_available()` → 연결 상태
2. GET `http://localhost:11434/api/tags` → 로드된 모델 목록
3. 간단한 ping 프롬프트로 응답 시간 측정

### Step 3: Gemma 4 호출

```python
from ml.gemma_client import GemmaClient

client = GemmaClient()
response = client.chat(
    messages=[{"role": "user", "content": user_input}],
    system_prompt=system_prompt,
    max_tokens=2048,
    temperature=0.3,
)
```

Bash로 호출하는 경우:
```bash
python -c "
from pathlib import Path
import sys
sys.path.insert(0, str(Path('C:/claude/.claude')))
from ml.gemma_client import GemmaClient
client = GemmaClient()
if not client.is_available():
    print('ERROR: Ollama 미연결')
    sys.exit(1)
r = client.chat([{'role': 'user', 'content': '''USER_PROMPT'''}], system_prompt='''SYSTEM_PROMPT''')
print(r.content)
print(f'\n---\nLocal Model (Gemma 4) | {r.tokens_used} tokens | {r.latency_ms}ms')
"
```

### Step 4: 결과 출력

응답 끝에 라벨 추가:
```
---
Local Model (Gemma 4) | {tokens_used} tokens | {latency_ms}ms
```

## /auto 연동

/auto 워크플로우에서 자동 위임 조건:
1. 복잡도 score <= 1
2. 텍스트 전용 작업 (delegation_keywords 매칭)
3. 코드/파일 작업 미포함
4. Ollama 상태 정상

위임 실패 시 기존 /auto 경로로 fallback.

## 주의사항

- Ollama는 한 번에 하나의 모델만 로드 가능 (RTX 5080 16GB VRAM 제약)
- GGUF Q4 양자화 — 복잡한 추론이나 코드 생성에는 Claude 사용 권장
- 응답 품질이 낮으면 Claude fallback 고려
