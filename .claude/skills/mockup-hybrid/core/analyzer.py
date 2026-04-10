"""
프롬프트 분석 및 자동 백엔드 선택

사용자 프롬프트와 옵션을 분석하여 최적의 목업 생성 백엔드를 선택합니다.
"""

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import yaml

# 라이브러리 임포트
import sys
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent.parent))

from lib.mockup_hybrid import MockupBackend, SelectionReason, MockupOptions
from lib.mockup_hybrid.stitch_client import get_stitch_client


@dataclass
class AnalysisResult:
    """분석 결과"""
    backend: MockupBackend
    reason: SelectionReason
    confidence: float  # 0.0 ~ 1.0
    details: str


class DesignContextAnalyzer:
    """프롬프트 분석기"""

    def __init__(self, rules_path: Optional[Path] = None):
        """
        분석기 초기화

        Args:
            rules_path: 선택 규칙 YAML 파일 경로
        """
        if rules_path is None:
            rules_path = Path(__file__).parent.parent / "config" / "selection_rules.yaml"

        self.rules = self._load_rules(rules_path)
        self.stitch_client = get_stitch_client()

    def _load_rules(self, path: Path) -> dict:
        """선택 규칙 로드"""
        if path.exists():
            with open(path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f)
        else:
            # 기본 규칙
            return {
                "rules": {
                    "keywords": {
                        "stitch_triggers": ["프레젠테이션", "고품질", "리뷰용"],
                        "html_triggers": ["빠른", "구조", "와이어프레임"],
                    },
                    "context": {
                        "prd_linked": "stitch",
                        "multi_screen_threshold": 3,
                        "multi_screen_backend": "html",
                    },
                    "default": "html",
                },
                "fallback": {"enabled": True, "from": "stitch", "to": "html"},
            }

    def analyze(
        self,
        prompt: str,
        options: MockupOptions,
    ) -> AnalysisResult:
        """
        프롬프트와 옵션을 분석하여 백엔드 선택

        Args:
            prompt: 사용자 프롬프트 (화면 이름 + 설명)
            options: 목업 옵션

        Returns:
            AnalysisResult 객체
        """
        # 1순위: 강제 옵션
        if options.force_html:
            return AnalysisResult(
                backend=MockupBackend.HTML,
                reason=SelectionReason.FORCE_HTML,
                confidence=1.0,
                details="--force-html 옵션 지정",
            )

        if options.force_hifi:
            # Stitch 사용 가능 여부 확인
            if not self.stitch_client.is_available():
                return AnalysisResult(
                    backend=MockupBackend.HTML,
                    reason=SelectionReason.API_UNAVAILABLE,
                    confidence=1.0,
                    details="--force-hifi 지정했으나 Stitch API 불가",
                )
            return AnalysisResult(
                backend=MockupBackend.STITCH,
                reason=SelectionReason.FORCE_HIFI,
                confidence=1.0,
                details="--force-hifi 옵션 지정",
            )

        # 2순위: 키워드 분석
        keyword_result = self._analyze_keywords(prompt)
        if keyword_result:
            return keyword_result

        # 3순위: 컨텍스트 분석
        context_result = self._analyze_context(options)
        if context_result:
            return context_result

        # 4순위: 환경 검사 (Stitch 가능 여부)
        env_result = self._check_environment()
        if env_result:
            return env_result

        # 기본값: HTML
        return AnalysisResult(
            backend=MockupBackend.HTML,
            reason=SelectionReason.DEFAULT,
            confidence=0.5,
            details="기본값 (HTML)",
        )

    def _analyze_keywords(self, prompt: str) -> Optional[AnalysisResult]:
        """키워드 분석"""
        prompt_lower = prompt.lower()
        keywords = self.rules.get("rules", {}).get("keywords", {})

        # Stitch 트리거 확인
        stitch_triggers = keywords.get("stitch_triggers", [])
        for keyword in stitch_triggers:
            if keyword.lower() in prompt_lower:
                # Stitch 사용 가능 여부 확인
                if self.stitch_client.is_available():
                    return AnalysisResult(
                        backend=MockupBackend.STITCH,
                        reason=SelectionReason.HIFI_KEYWORD,
                        confidence=0.9,
                        details=f"고품질 키워드 감지: '{keyword}'",
                    )
                else:
                    # Stitch 불가 시 HTML로 폴백
                    return AnalysisResult(
                        backend=MockupBackend.HTML,
                        reason=SelectionReason.API_UNAVAILABLE,
                        confidence=0.8,
                        details=f"키워드 '{keyword}' 감지했으나 Stitch API 불가",
                    )

        # HTML 트리거 확인
        html_triggers = keywords.get("html_triggers", [])
        for keyword in html_triggers:
            if keyword.lower() in prompt_lower:
                return AnalysisResult(
                    backend=MockupBackend.HTML,
                    reason=SelectionReason.HTML_KEYWORD,
                    confidence=0.9,
                    details=f"빠른/구조 키워드 감지: '{keyword}'",
                )

        return None

    def _analyze_context(self, options: MockupOptions) -> Optional[AnalysisResult]:
        """컨텍스트 분석"""
        context = self.rules.get("rules", {}).get("context", {})

        # PRD 연결 확인
        if options.prd:
            prd_backend = context.get("prd_linked", "stitch")
            if prd_backend == "stitch":
                if self.stitch_client.is_available():
                    return AnalysisResult(
                        backend=MockupBackend.STITCH,
                        reason=SelectionReason.PRD_LINKED,
                        confidence=0.85,
                        details=f"PRD 연결: {options.prd} (문서용 고품질)",
                    )
                else:
                    return AnalysisResult(
                        backend=MockupBackend.HTML,
                        reason=SelectionReason.API_UNAVAILABLE,
                        confidence=0.7,
                        details=f"PRD 연결했으나 Stitch API 불가",
                    )

        # 다중 화면 확인
        threshold = context.get("multi_screen_threshold", 3)
        if options.screens >= threshold:
            return AnalysisResult(
                backend=MockupBackend.HTML,
                reason=SelectionReason.MULTI_SCREEN,
                confidence=0.8,
                details=f"다중 화면 ({options.screens}개) - 빠른 생성",
            )

        return None

    def _check_environment(self) -> Optional[AnalysisResult]:
        """환경 검사"""
        # Stitch Rate Limit 확인
        if self.stitch_client.is_rate_limited():
            return AnalysisResult(
                backend=MockupBackend.HTML,
                reason=SelectionReason.RATE_LIMITED,
                confidence=1.0,
                details="Stitch API Rate Limit 초과",
            )

        return None

    def get_backend_info(self, backend: MockupBackend) -> dict:
        """백엔드 정보 반환"""
        backends = self.rules.get("backends", {})
        backend_key = backend.value
        return backends.get(backend_key, {
            "name": backend_key.upper(),
            "emoji": "📄",
            "description": "",
            "avg_time_seconds": 10,
            "suffix": "",
        })
