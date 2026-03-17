"""
omc_bridge.py - OMC + BKIT 통합 에이전트 브리지

OMC 32개 + BKIT 11개 = 43개 에이전트 통합 관리
병렬 호출 및 비교 검토 로직 포함
"""

from dataclasses import dataclass
from typing import List, Optional, Dict, Tuple
from enum import Enum


class OMCSkill(Enum):
    """OMC 스킬 열거형"""
    RALPLAN = "ralplan"
    ULTRAWORK = "ultrawork"
    RALPH = "ralph"
    ARCHITECT = "architect"
    REVIEW = "review"
    BUILD_FIX = "build-fix"
    AUTOPILOT = "autopilot"
    ULTRAQA = "ultraqa"


class BKITSkill(Enum):
    """BKIT 스킬 열거형"""
    PDCA = "bkit:pdca"
    STARTER = "bkit:starter"
    DYNAMIC = "bkit:dynamic"
    ENTERPRISE = "bkit:enterprise"
    CODE_REVIEW = "bkit:code-review"
    DEVELOPMENT_PIPELINE = "bkit:development-pipeline"


class ModelTier(Enum):
    """모델 티어"""
    HAIKU = "haiku"
    SONNET = "sonnet"
    OPUS = "opus"


class AgentDomain(Enum):
    """에이전트 도메인 분류"""
    ANALYSIS = "analysis"
    EXECUTION = "execution"
    SEARCH = "search"
    RESEARCH = "research"
    FRONTEND = "frontend"
    DOCS = "docs"
    VISUAL = "visual"
    PLANNING = "planning"
    TESTING = "testing"
    SECURITY = "security"
    BUILD = "build"
    TDD = "tdd"
    REVIEW = "review"
    DATA = "data"
    VERIFICATION = "verification"
    IMPROVEMENT = "improvement"
    GUIDE = "guide"
    BACKEND = "backend"
    ENTERPRISE = "enterprise"
    INFRA = "infra"
    PIPELINE = "pipeline"


@dataclass
class AgentInfo:
    """에이전트 정보"""
    agent_type: str
    model: ModelTier
    domain: AgentDomain
    source: str  # "omc" or "bkit"
    description: str = ""


@dataclass
class AgentConfig:
    """에이전트 호출 설정 (Agent Teams 패턴)"""
    agent_type: str
    model: ModelTier
    prompt: str
    name: str = ""        # Agent Teams: teammate 이름 (필수)
    team_name: str = ""   # Agent Teams: 팀 이름 (필수)


@dataclass
class AgentResult:
    """에이전트 실행 결과"""
    agent_type: str
    success: bool
    output: str
    source: str  # "omc" or "bkit"
    error: Optional[str] = None
    execution_time_ms: int = 0


@dataclass
class ComparisonResult:
    """병렬 비교 검토 결과"""
    omc_result: Optional[AgentResult] = None
    bkit_result: Optional[AgentResult] = None
    winner: Optional[str] = None  # "omc", "bkit", "both", "none"
    comparison_notes: str = ""
    merged_output: str = ""
    confidence: float = 0.0


@dataclass
class PlanResult:
    """계획 결과"""
    success: bool
    plan_path: str
    iterations: int
    consensus_reached: bool


@dataclass
class ExecutionResult:
    """실행 결과"""
    success: bool
    completed_tasks: List[str]
    failed_tasks: List[str]
    agents_spawned: int


@dataclass
class RalphResult:
    """Ralph 루프 결과"""
    success: bool
    iterations: int
    architect_approved: bool
    final_status: str


@dataclass
class VerificationResult:
    """검증 결과"""
    approved: bool
    feedback: str
    issues: List[str]
    match_percentage: float = 0.0  # BKIT gap-detector용


# =============================================================================
# 통합 에이전트 레지스트리 (43개)
# =============================================================================

UNIFIED_AGENT_REGISTRY: Dict[str, AgentInfo] = {
    # -------------------------------------------------------------------------
    # OMC 에이전트 (32개)
    # -------------------------------------------------------------------------
    # Analysis (3)
    "architect-low": AgentInfo(
        "architect-low", ModelTier.HAIKU, AgentDomain.ANALYSIS,
        "omc", "간단한 구조 분석"
    ),
    "architect-medium": AgentInfo(
        "architect-medium", ModelTier.SONNET, AgentDomain.ANALYSIS,
        "omc", "중간 규모 설계"
    ),
    "architect": AgentInfo(
        "architect", ModelTier.OPUS, AgentDomain.ANALYSIS,
        "omc", "복잡한 아키텍처 분석"
    ),
    # Execution (3)
    "executor-low": AgentInfo(
        "executor-low", ModelTier.HAIKU, AgentDomain.EXECUTION,
        "omc", "단순 코드 변경"
    ),
    "executor": AgentInfo(
        "executor", ModelTier.SONNET, AgentDomain.EXECUTION,
        "omc", "기능 구현"
    ),
    "executor-high": AgentInfo(
        "executor-high", ModelTier.OPUS, AgentDomain.EXECUTION,
        "omc", "복잡한 리팩토링"
    ),
    # Search (3)
    "explore": AgentInfo(
        "explore", ModelTier.HAIKU, AgentDomain.SEARCH,
        "omc", "기본 코드베이스 탐색"
    ),
    "explore-medium": AgentInfo(
        "explore-medium", ModelTier.SONNET, AgentDomain.SEARCH,
        "omc", "상세 코드 탐색"
    ),
    "explore-high": AgentInfo(
        "explore-high", ModelTier.OPUS, AgentDomain.SEARCH,
        "omc", "심층 코드 분석"
    ),
    # Research (2)
    "researcher-low": AgentInfo(
        "researcher-low", ModelTier.HAIKU, AgentDomain.RESEARCH,
        "omc", "빠른 문서 조회"
    ),
    "researcher": AgentInfo(
        "researcher", ModelTier.SONNET, AgentDomain.RESEARCH,
        "omc", "리서치"
    ),
    # Frontend (3)
    "designer-low": AgentInfo(
        "designer-low", ModelTier.HAIKU, AgentDomain.FRONTEND,
        "omc", "간단한 UI 수정"
    ),
    "designer": AgentInfo(
        "designer", ModelTier.SONNET, AgentDomain.FRONTEND,
        "omc", "UI 컴포넌트"
    ),
    "designer-high": AgentInfo(
        "designer-high", ModelTier.OPUS, AgentDomain.FRONTEND,
        "omc", "디자인 시스템"
    ),
    # Docs (1)
    "writer": AgentInfo(
        "writer", ModelTier.HAIKU, AgentDomain.DOCS,
        "omc", "문서 작성"
    ),
    # Visual (1)
    "vision": AgentInfo(
        "vision", ModelTier.SONNET, AgentDomain.VISUAL,
        "omc", "이미지/다이어그램 분석"
    ),
    # Planning (3)
    "planner": AgentInfo(
        "planner", ModelTier.OPUS, AgentDomain.PLANNING,
        "omc", "전략적 계획"
    ),
    "critic": AgentInfo(
        "critic", ModelTier.OPUS, AgentDomain.PLANNING,
        "omc", "계획 비평"
    ),
    "analyst": AgentInfo(
        "analyst", ModelTier.OPUS, AgentDomain.PLANNING,
        "omc", "사전 분석"
    ),
    # Testing (2)
    "qa-tester": AgentInfo(
        "qa-tester", ModelTier.SONNET, AgentDomain.TESTING,
        "omc", "테스트 실행"
    ),
    "qa-tester-high": AgentInfo(
        "qa-tester-high", ModelTier.OPUS, AgentDomain.TESTING,
        "omc", "복잡한 테스트"
    ),
    # Security (2)
    "security-reviewer-low": AgentInfo(
        "security-reviewer-low", ModelTier.HAIKU, AgentDomain.SECURITY,
        "omc", "빠른 보안 스캔"
    ),
    "security-reviewer": AgentInfo(
        "security-reviewer", ModelTier.OPUS, AgentDomain.SECURITY,
        "omc", "심층 보안 분석"
    ),
    # Build (2)
    "build-fixer-low": AgentInfo(
        "build-fixer-low", ModelTier.HAIKU, AgentDomain.BUILD,
        "omc", "단순 빌드 오류"
    ),
    "build-fixer": AgentInfo(
        "build-fixer", ModelTier.SONNET, AgentDomain.BUILD,
        "omc", "빌드 오류 수정"
    ),
    # TDD (2)
    "tdd-guide-low": AgentInfo(
        "tdd-guide-low", ModelTier.HAIKU, AgentDomain.TDD,
        "omc", "기본 테스트 제안"
    ),
    "tdd-guide": AgentInfo(
        "tdd-guide", ModelTier.SONNET, AgentDomain.TDD,
        "omc", "TDD 워크플로우"
    ),
    # Review (2)
    "code-reviewer-low": AgentInfo(
        "code-reviewer-low", ModelTier.HAIKU, AgentDomain.REVIEW,
        "omc", "빠른 코드 검토"
    ),
    "code-reviewer": AgentInfo(
        "code-reviewer", ModelTier.OPUS, AgentDomain.REVIEW,
        "omc", "상세 코드 리뷰"
    ),
    # Data (3)
    "scientist-low": AgentInfo(
        "scientist-low", ModelTier.HAIKU, AgentDomain.DATA,
        "omc", "간단한 데이터 확인"
    ),
    "scientist": AgentInfo(
        "scientist", ModelTier.SONNET, AgentDomain.DATA,
        "omc", "데이터 분석"
    ),
    "scientist-high": AgentInfo(
        "scientist-high", ModelTier.OPUS, AgentDomain.DATA,
        "omc", "ML/통계 분석"
    ),

    # -------------------------------------------------------------------------
    # BKIT 에이전트 (11개)
    # -------------------------------------------------------------------------
    "bkit:starter-guide": AgentInfo(
        "bkit:starter-guide", ModelTier.SONNET, AgentDomain.GUIDE,
        "bkit", "초보자 가이드"
    ),
    "bkit:bkend-expert": AgentInfo(
        "bkit:bkend-expert", ModelTier.SONNET, AgentDomain.BACKEND,
        "bkit", "BaaS 전문가"
    ),
    "bkit:enterprise-expert": AgentInfo(
        "bkit:enterprise-expert", ModelTier.OPUS, AgentDomain.ENTERPRISE,
        "bkit", "엔터프라이즈 전문가"
    ),
    "bkit:infra-architect": AgentInfo(
        "bkit:infra-architect", ModelTier.OPUS, AgentDomain.INFRA,
        "bkit", "인프라 아키텍트"
    ),
    "bkit:pipeline-guide": AgentInfo(
        "bkit:pipeline-guide", ModelTier.SONNET, AgentDomain.PIPELINE,
        "bkit", "파이프라인 가이드"
    ),
    "bkit:gap-detector": AgentInfo(
        "bkit:gap-detector", ModelTier.OPUS, AgentDomain.VERIFICATION,
        "bkit", "설계-구현 갭 분석"
    ),
    "bkit:design-validator": AgentInfo(
        "bkit:design-validator", ModelTier.SONNET, AgentDomain.VERIFICATION,
        "bkit", "설계 문서 검증"
    ),
    "bkit:code-analyzer": AgentInfo(
        "bkit:code-analyzer", ModelTier.SONNET, AgentDomain.REVIEW,
        "bkit", "코드 품질 분석"
    ),
    "bkit:qa-monitor": AgentInfo(
        "bkit:qa-monitor", ModelTier.SONNET, AgentDomain.TESTING,
        "bkit", "QA 모니터링"
    ),
    "bkit:pdca-iterator": AgentInfo(
        "bkit:pdca-iterator", ModelTier.SONNET, AgentDomain.IMPROVEMENT,
        "bkit", "Check-Act 반복 개선"
    ),
    "bkit:report-generator": AgentInfo(
        "bkit:report-generator", ModelTier.HAIKU, AgentDomain.DOCS,
        "bkit", "완료 보고서 생성"
    ),
}


# =============================================================================
# 도메인별 에이전트 매핑 (비교 검토용)
# =============================================================================

DOMAIN_AGENT_PAIRS: Dict[AgentDomain, Dict[str, List[str]]] = {
    # 코드 리뷰: OMC code-reviewer vs BKIT code-analyzer
    AgentDomain.REVIEW: {
        "omc": ["code-reviewer", "code-reviewer-low"],
        "bkit": ["bkit:code-analyzer"],
    },
    # 테스트/QA: OMC qa-tester vs BKIT qa-monitor
    AgentDomain.TESTING: {
        "omc": ["qa-tester", "qa-tester-high"],
        "bkit": ["bkit:qa-monitor"],
    },
    # 검증: OMC architect vs BKIT gap-detector
    AgentDomain.VERIFICATION: {
        "omc": ["architect"],
        "bkit": ["bkit:gap-detector", "bkit:design-validator"],
    },
    # 문서: OMC writer vs BKIT report-generator
    AgentDomain.DOCS: {
        "omc": ["writer"],
        "bkit": ["bkit:report-generator"],
    },
    # 분석: OMC architect vs BKIT enterprise-expert
    AgentDomain.ANALYSIS: {
        "omc": ["architect", "architect-medium", "architect-low"],
        "bkit": ["bkit:enterprise-expert", "bkit:infra-architect"],
    },
}


# BKIT 에이전트 -> OMC 폴백 매핑
BKIT_TO_OMC_FALLBACK: Dict[str, str] = {
    "bkit:gap-detector": "architect",
    "bkit:design-validator": "architect-medium",
    "bkit:code-analyzer": "code-reviewer",
    "bkit:qa-monitor": "qa-tester",
    "bkit:pdca-iterator": "executor",
    "bkit:report-generator": "writer",
    "bkit:starter-guide": "writer",
    "bkit:bkend-expert": "architect-medium",
    "bkit:enterprise-expert": "architect",
    "bkit:infra-architect": "architect",
    "bkit:pipeline-guide": "executor",
}


class OMCBridge:
    """OMC + BKIT 통합 에이전트 브리지"""

    def __init__(self):
        self.registry = UNIFIED_AGENT_REGISTRY
        self.domain_pairs = DOMAIN_AGENT_PAIRS

    # -------------------------------------------------------------------------
    # 에이전트 조회
    # -------------------------------------------------------------------------

    def get_agent(self, agent_type: str) -> Optional[AgentInfo]:
        """에이전트 정보 조회"""
        return self.registry.get(agent_type)

    def get_agent_with_fallback(self, agent_type: str, force_omc: bool = False) -> Tuple[str, Optional[AgentInfo], bool]:
        """에이전트 조회 (BKIT 호출 불가 시 OMC로 폴백)

        BKIT 플러그인이 활성화된 상태에서는 force_omc=False (기본값)로
        BKIT 에이전트를 직접 호출합니다. BKIT이 비활성화된 경우에만
        force_omc=True로 설정하여 OMC로 폴백합니다.

        Args:
            agent_type: 요청된 에이전트 타입
            force_omc: True면 bkit: prefix 에이전트를 항상 OMC로 폴백 (기본값: False)

        Returns:
            Tuple[실제 사용할 agent_type, AgentInfo, 폴백 발생 여부]
        """
        # BKIT 에이전트인 경우 OMC로 폴백 (force_omc=True일 때만)
        if force_omc and agent_type.startswith("bkit:"):
            fallback = BKIT_TO_OMC_FALLBACK.get(agent_type)
            if fallback:
                fallback_agent = self.get_agent(fallback)
                if fallback_agent:
                    return fallback, fallback_agent, True
            return agent_type, None, True

        # OMC 에이전트 또는 force_omc=False인 경우
        agent = self.get_agent(agent_type)
        if agent:
            return agent_type, agent, False

        return agent_type, None, False

    def get_agents_by_domain(self, domain: AgentDomain) -> List[AgentInfo]:
        """도메인별 에이전트 목록"""
        return [info for info in self.registry.values() if info.domain == domain]

    def get_agents_by_source(self, source: str) -> List[AgentInfo]:
        """소스별 에이전트 목록 (omc 또는 bkit)"""
        return [info for info in self.registry.values() if info.source == source]

    def get_agents_by_model(self, model: ModelTier) -> List[AgentInfo]:
        """모델별 에이전트 목록"""
        return [info for info in self.registry.values() if info.model == model]

    # -------------------------------------------------------------------------
    # 비교 가능한 에이전트 쌍 조회
    # -------------------------------------------------------------------------

    def get_comparable_agents(self, domain: AgentDomain) -> Optional[Dict[str, List[str]]]:
        """특정 도메인에서 비교 가능한 OMC/BKIT 에이전트 쌍 반환"""
        return self.domain_pairs.get(domain)

    def find_bkit_counterpart(self, omc_agent: str) -> Optional[str]:
        """OMC 에이전트에 대응하는 BKIT 에이전트 찾기"""
        omc_info = self.get_agent(omc_agent)
        if not omc_info or omc_info.source != "omc":
            return None

        pairs = self.get_comparable_agents(omc_info.domain)
        if pairs and "bkit" in pairs and pairs["bkit"]:
            for bkit_agent in pairs["bkit"]:
                bkit_info = self.get_agent(bkit_agent)
                if bkit_info and bkit_info.model == omc_info.model:
                    return bkit_agent
            return pairs["bkit"][0]
        return None

    def find_omc_counterpart(self, bkit_agent: str) -> Optional[str]:
        """BKIT 에이전트에 대응하는 OMC 에이전트 찾기"""
        bkit_info = self.get_agent(bkit_agent)
        if not bkit_info or bkit_info.source != "bkit":
            return None

        pairs = self.get_comparable_agents(bkit_info.domain)
        if pairs and "omc" in pairs and pairs["omc"]:
            for omc_agent in pairs["omc"]:
                omc_info = self.get_agent(omc_agent)
                if omc_info and omc_info.model == bkit_info.model:
                    return omc_agent
            return pairs["omc"][0]
        return None

    # -------------------------------------------------------------------------
    # 커맨드 -> 에이전트 매핑
    # -------------------------------------------------------------------------

    COMMAND_AGENT_MAP: Dict[str, Tuple[str, ModelTier]] = {
        "/debug": ("architect", ModelTier.OPUS),
        "/check --fix": ("build-fixer", ModelTier.SONNET),
        "/check --security": ("security-reviewer", ModelTier.OPUS),
        "/issue fix": ("executor", ModelTier.SONNET),
        "/pr auto": ("code-reviewer", ModelTier.OPUS),
        "/tdd": ("tdd-guide", ModelTier.SONNET),
        "/research": ("researcher", ModelTier.SONNET),
        "/audit quick": ("explore", ModelTier.HAIKU),
        # BKIT 스킬 (bkit:pdca 플러그인 경유, 로컬 커맨드 파일 없음)
        "/pdca analyze": ("bkit:gap-detector", ModelTier.OPUS),
        "/pdca iterate": ("bkit:pdca-iterator", ModelTier.SONNET),
        "/pdca report": ("bkit:report-generator", ModelTier.HAIKU),
    }

    def get_agent_for_command(self, command: str) -> Optional[AgentConfig]:
        """커맨드에 적합한 에이전트 반환"""
        if command in self.COMMAND_AGENT_MAP:
            agent_type, model = self.COMMAND_AGENT_MAP[command]
            return AgentConfig(agent_type=agent_type, model=model, prompt="")
        return None

    # -------------------------------------------------------------------------
    # Task 호출 코드 생성
    # -------------------------------------------------------------------------

    def build_task_call(self, agent_config: AgentConfig) -> str:
        """Task tool 호출 코드 생성 (Agent Teams 패턴)

        Agent Teams 필수: name + team_name 포함.
        생성된 코드는 TeamCreate → Task(name, team_name) → SendMessage 패턴을 따름.
        """
        return f'''Task(
    subagent_type="{agent_config.agent_type}",
    name="{agent_config.name}",
    team_name="{agent_config.team_name}",
    model="{agent_config.model.value}",
    prompt="""{agent_config.prompt}"""
)
SendMessage(type="message", recipient="{agent_config.name}",
    content="Task 할당. 완료 후 TaskUpdate로 completed 처리.")'''

    def build_task_call_with_fallback(self, agent_config: AgentConfig) -> Tuple[str, bool, str]:
        """Task tool 호출 코드 생성 (BKIT 폴백 자동 처리)"""
        actual_agent, agent_info, did_fallback = self.get_agent_with_fallback(agent_config.agent_type)

        fallback_message = ""
        if did_fallback:
            fallback_message = f"[BKIT Fallback] {agent_config.agent_type} -> {actual_agent}"

        actual_model = agent_info.model if agent_info else agent_config.model
        updated_config = AgentConfig(
            agent_type=actual_agent,
            model=actual_model,
            prompt=agent_config.prompt,
            name=agent_config.name,
            team_name=agent_config.team_name
        )

        task_call = self.build_task_call(updated_config)
        return task_call, did_fallback, fallback_message

    def resolve_agent_for_pdca_check(self, use_bkit: bool = True) -> Tuple[str, str]:
        """PDCA Check 단계용 에이전트 결정 (이중 검증)"""
        primary = "architect"

        if use_bkit:
            secondary_agent, _, did_fallback = self.get_agent_with_fallback("bkit:gap-detector")
            if did_fallback:
                return primary, ""
            return primary, "bkit:gap-detector"

        return primary, ""

    def build_verification_comparison_call(
        self,
        design_doc: str,
        implementation: str,
        gap_threshold: int = 90,
        team_name: str = "pdca-verify"
    ) -> str:
        """설계-구현 검증을 위한 순차 비교 호출 (Agent Teams 패턴: Architect → gap-detector)"""
        return f'''# ============================================================
# 이중 검증: OMC Architect + BKIT gap-detector (Agent Teams)
# ============================================================

# 팀은 이미 생성되어 있어야 함 (team_name="{team_name}")

# 1. OMC Architect 검증 (기능적 완성도) - 순차 teammate
Task(
    subagent_type="architect",
    name="verifier",
    team_name="{team_name}",
    model="opus",
    prompt="""## 설계 문서
{design_doc}

## 구현 코드
{implementation}

## 검증 항목
1. 원래 요청을 완전히 충족하는가?
2. 명백한 버그가 있는가?
3. 누락된 엣지 케이스가 있는가?
4. 코드 품질이 수용 가능한가?

## 출력
- verdict: APPROVED 또는 REJECTED
- issues: [발견된 이슈 목록]
- feedback: 상세 피드백"""
)
SendMessage(type="message", recipient="verifier",
    content="검증 시작. APPROVE/REJECT 판정 후 TaskUpdate 처리.")
# verifier 완료 대기 → shutdown_request

# 2. BKIT gap-detector 검증 (설계-구현 일치도) - verifier 완료 후 순차 실행
Task(
    subagent_type="bkit:gap-detector",
    name="gap-checker",
    team_name="{team_name}",
    model="opus",
    prompt="""## 설계 문서
{design_doc}

## 구현 코드
{implementation}

## 검증 항목
1. 설계에 명시된 기능이 모두 구현되었는가?
2. 구현이 설계를 정확히 따르는가?
3. 누락된 기능이 있는가?
4. 추가된 기능이 있는가?

## 임계값
통과 기준: {gap_threshold}%

## 출력
- match_percentage: 0-100
- verdict: PASS (>={gap_threshold}%) / WARN (70-{gap_threshold-1}%) / FAIL (<70%)
- gaps: [설계에 있으나 구현에 없는 항목]
- extras: [구현에 있으나 설계에 없는 항목]
- recommendations: [권장 조치사항]"""
)
SendMessage(type="message", recipient="gap-checker",
    content="갭 분석 시작. 완료 후 TaskUpdate 처리.")
# gap-checker 완료 대기 → shutdown_request

# 두 검증 결과를 종합하여 최종 판정
# - Architect APPROVED + gap >= {gap_threshold}% -> 완료
# - 둘 중 하나라도 실패 -> 개선 필요
'''

    # -------------------------------------------------------------------------
    # 결과 비교 및 병합
    # -------------------------------------------------------------------------

    def compare_results(
        self,
        omc_result: AgentResult,
        bkit_result: AgentResult
    ) -> ComparisonResult:
        """두 에이전트 결과를 비교하여 최선의 결과 선택"""
        comparison = ComparisonResult(
            omc_result=omc_result,
            bkit_result=bkit_result
        )

        if not omc_result.success and not bkit_result.success:
            comparison.winner = "none"
            comparison.comparison_notes = "Both agents failed"
            return comparison

        if omc_result.success and not bkit_result.success:
            comparison.winner = "omc"
            comparison.merged_output = omc_result.output
            comparison.confidence = 0.7
            comparison.comparison_notes = "Only OMC succeeded"
            return comparison

        if bkit_result.success and not omc_result.success:
            comparison.winner = "bkit"
            comparison.merged_output = bkit_result.output
            comparison.confidence = 0.7
            comparison.comparison_notes = "Only BKIT succeeded"
            return comparison

        comparison.winner = "both"
        comparison.confidence = 0.9
        comparison.comparison_notes = "Both agents succeeded, results merged"
        comparison.merged_output = f"""## OMC 분석 결과
{omc_result.output}

## BKIT 분석 결과
{bkit_result.output}

## 종합
양쪽 분석을 종합하여 검토하세요."""

        return comparison


# =============================================================================
# 편의 함수
# =============================================================================

def get_omc_bridge() -> OMCBridge:
    """OMCBridge 인스턴스 반환"""
    return OMCBridge()


def get_agent_count() -> Dict[str, int]:
    """에이전트 수 통계"""
    bridge = OMCBridge()
    omc_count = len(bridge.get_agents_by_source("omc"))
    bkit_count = len(bridge.get_agents_by_source("bkit"))
    return {
        "omc": omc_count,
        "bkit": bkit_count,
        "total": omc_count + bkit_count
    }


def list_comparable_domains() -> List[AgentDomain]:
    """비교 가능한 도메인 목록"""
    return list(DOMAIN_AGENT_PAIRS.keys())


# =============================================================================
# 테스트/실행
# =============================================================================

if __name__ == "__main__":
    bridge = OMCBridge()

    # 에이전트 수 확인
    counts = get_agent_count()
    print(f"에이전트 수: OMC {counts['omc']}개, BKIT {counts['bkit']}개, 총 {counts['total']}개")

    # 비교 가능한 도메인
    print(f"\n비교 가능한 도메인: {[d.value for d in list_comparable_domains()]}")

    # BKIT 직접 호출 테스트 (force_omc=False 기본값)
    print("\n=== BKIT 직접 호출 테스트 (force_omc=False) ===")
    test_bkit_agents = [
        "bkit:gap-detector",
        "bkit:code-analyzer",
        "bkit:qa-monitor",
        "bkit:pdca-iterator"
    ]
    for bkit_agent in test_bkit_agents:
        actual_agent, agent_info, did_fallback = bridge.get_agent_with_fallback(bkit_agent)
        if agent_info:
            fallback_status = " (폴백됨)" if did_fallback else " (직접 호출)"
            print(f"{bkit_agent} -> {actual_agent}{fallback_status} ({agent_info.model.value})")
        else:
            print(f"{bkit_agent} -> 조회 실패")

    # BKIT 폴백 테스트 (force_omc=True)
    print("\n=== BKIT 폴백 테스트 (force_omc=True) ===")
    for bkit_agent in test_bkit_agents:
        actual_agent, agent_info, did_fallback = bridge.get_agent_with_fallback(bkit_agent, force_omc=True)
        if agent_info:
            fallback_status = " (폴백됨)" if did_fallback else ""
            print(f"{bkit_agent} -> {actual_agent}{fallback_status} ({agent_info.model.value})")
        else:
            print(f"{bkit_agent} -> 폴백 실패")

    # OMC 에이전트 정상 조회
    print("\n=== OMC 에이전트 정상 조회 ===")
    test_omc_agents = [
        "architect",
        "executor",
    ]
    for omc_agent in test_omc_agents:
        actual_agent, agent_info, did_fallback = bridge.get_agent_with_fallback(omc_agent)
        if agent_info:
            print(f"{omc_agent} -> {actual_agent} ({agent_info.model.value})")

    # 이중 검증 에이전트 결정
    print("\n=== PDCA Check 이중 검증 ===")
    primary, secondary = bridge.resolve_agent_for_pdca_check(use_bkit=True)
    print(f"Primary: {primary}, Secondary: {secondary or '(없음)'}")
