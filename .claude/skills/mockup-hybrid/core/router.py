"""
백엔드 라우터

분석 결과에 따라 적절한 어댑터로 요청을 라우팅합니다.
"""

from pathlib import Path
from typing import Optional

import sys
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent.parent))

from lib.mockup_hybrid import (
    MockupBackend,
    MockupResult,
    MockupOptions,
    SelectionReason,
    DEFAULT_MOCKUP_DIR,
    DEFAULT_IMAGE_DIR,
)
from lib.mockup_hybrid.export_utils import (
    save_html,
    capture_screenshot,
    get_output_paths,
)

from .analyzer import DesignContextAnalyzer, AnalysisResult
from .fallback_handler import FallbackHandler
from ..adapters.html_adapter import HTMLAdapter
from ..adapters.stitch_adapter import StitchAdapter
from ..adapters.mermaid_adapter import MermaidAdapter
from .document_scanner import DocumentScanner, DocumentScanResult
from .document_embedder import DocumentEmbedder


class MockupRouter:
    """백엔드 라우터"""

    def __init__(
        self,
        html_adapter: Optional[HTMLAdapter] = None,
        stitch_adapter: Optional[StitchAdapter] = None,
        mermaid_adapter: Optional[MermaidAdapter] = None,
        analyzer: Optional[DesignContextAnalyzer] = None,
        fallback_handler: Optional[FallbackHandler] = None,
    ):
        """
        라우터 초기화

        Args:
            html_adapter: HTML 어댑터
            stitch_adapter: Stitch 어댑터
            mermaid_adapter: Mermaid 어댑터
            analyzer: 프롬프트 분석기
            fallback_handler: 폴백 핸들러
        """
        self.html_adapter = html_adapter or HTMLAdapter()
        self.stitch_adapter = stitch_adapter or StitchAdapter()
        self.mermaid_adapter = mermaid_adapter or MermaidAdapter()
        self.analyzer = analyzer or DesignContextAnalyzer()
        self.fallback_handler = fallback_handler or FallbackHandler()

    def route(
        self,
        prompt: str,
        options: Optional[MockupOptions] = None,
        output_dir: Optional[Path] = None,
        image_dir: Optional[Path] = None,
    ) -> MockupResult:
        """
        요청 라우팅 및 목업 생성

        Args:
            prompt: 사용자 프롬프트
            options: 목업 옵션
            output_dir: HTML 출력 디렉토리
            image_dir: 이미지 출력 디렉토리

        Returns:
            MockupResult 객체
        """
        options = options or MockupOptions()
        output_dir = output_dir or DEFAULT_MOCKUP_DIR
        image_dir = image_dir or DEFAULT_IMAGE_DIR

        # 0. 파일 경로 감지 → 문서 모드
        prompt_path = Path(prompt)
        if prompt_path.suffix in ('.md', '.markdown') and prompt_path.exists():
            self.route_document(
                doc_path=prompt_path,
                options=options,
                output_dir=output_dir,
                image_dir=image_dir,
            )
            # 문서 모드는 별도 결과 반환
            return MockupResult(
                backend=MockupBackend.MERMAID,
                reason=SelectionReason.DEFAULT,
                html_path=prompt_path,
                image_path=None,
                success=True,
                message=f"📄 문서 기반 목업 생성 완료: {prompt_path}",
                fallback_used=False,
            )

        # 1. 프롬프트 분석
        analysis = self.analyzer.analyze(prompt, options)
        backend_info = self.analyzer.get_backend_info(analysis.backend)

        # 2. 출력 경로 생성
        suffix = backend_info.get("suffix", "")
        html_path, image_path = get_output_paths(
            name=self._extract_name(prompt),
            prd=options.prd,
            suffix=suffix,
            mockup_dir=output_dir,
            image_dir=image_dir,
        )

        # 3. 백엔드 실행
        result = self._execute_backend(
            backend=analysis.backend,
            prompt=prompt,
            options=options,
            html_path=html_path,
            image_path=image_path,
            analysis=analysis,
        )

        return result

    def route_document(
        self,
        doc_path: Path,
        options: Optional[MockupOptions] = None,
        output_dir: Optional[Path] = None,
        image_dir: Optional[Path] = None,
        force: bool = False,
        dry_run: bool = False,
    ) -> DocumentScanResult:
        """
        문서 기반 일괄 목업 생성

        문서를 스캔하여 시각화 필요 섹션을 발견하고,
        각 섹션에 적합한 목업을 자동 생성하여 문서에 삽입합니다.

        Args:
            doc_path: 마크다운 문서 경로
            options: 목업 옵션
            output_dir: HTML 출력 디렉토리
            image_dir: 이미지 출력 디렉토리
            force: True면 기존 시각화도 재생성
            dry_run: True면 스캔만 하고 생성하지 않음

        Returns:
            DocumentScanResult 객체
        """
        options = options or MockupOptions()
        output_dir = output_dir or DEFAULT_MOCKUP_DIR
        image_dir = image_dir or DEFAULT_IMAGE_DIR

        scanner = DocumentScanner()
        embedder = DocumentEmbedder()

        # 1. 문서 스캔
        scan_result = scanner.scan(doc_path, force=force)

        if dry_run:
            return scan_result

        if scan_result.mockup_count == 0:
            return scan_result

        # 2. 각 NEED 섹션에 대해 목업 생성
        generation_results = []
        for section in scan_result.need_sections:
            # 섹션의 suggested_tier를 force 옵션으로 변환
            section_options = MockupOptions(
                bnw=options.bnw,
                force_mermaid=section.suggested_tier == MockupBackend.MERMAID,
                force_html=section.suggested_tier == MockupBackend.HTML,
                force_hifi=section.suggested_tier == MockupBackend.STITCH,
                prd=options.prd,
            )

            # 섹션 제목 + 본문을 프롬프트로 사용
            heading_text = section.heading.lstrip('#').strip()
            prompt = f"{heading_text}: {section.content[:200]}"

            mockup_result = self.route(
                prompt=prompt,
                options=section_options,
                output_dir=output_dir,
                image_dir=image_dir,
            )

            generation_results.append((section, mockup_result))

        # 3. 문서에 결과 삽입
        embedder.embed_batch(doc_path, generation_results)

        return scan_result

    def _execute_backend(
        self,
        backend: MockupBackend,
        prompt: str,
        options: MockupOptions,
        html_path: Path,
        image_path: Path,
        analysis: AnalysisResult,
    ) -> MockupResult:
        """백엔드 실행"""
        fallback_used = False
        final_backend = backend
        final_reason = analysis.reason

        if backend == MockupBackend.MERMAID:
            # Mermaid 코드 생성
            mermaid_result = self.mermaid_adapter.generate_from_prompt(prompt)

            if mermaid_result.success:
                screen_name = self._extract_name(prompt)
                output_dir = html_path.parent if html_path else DEFAULT_MOCKUP_DIR

                # .mermaid.md 저장 (마크다운 원본 유지)
                md_path = output_dir / f"{screen_name}.mermaid.md"
                md_path.parent.mkdir(parents=True, exist_ok=True)
                md_content = f"# {screen_name}\n\n```mermaid\n{mermaid_result.mermaid_code}\n```\n"
                md_path.write_text(md_content, encoding="utf-8")

                # HTML 래퍼 저장 (width/height auto, max 720/1280 제약 적용)
                html_wrapper = self.mermaid_adapter.to_html_wrapper(
                    mermaid_result.mermaid_code,
                    title=screen_name,
                )
                html_path.parent.mkdir(parents=True, exist_ok=True)
                html_path.write_text(html_wrapper, encoding="utf-8")

                # 스크린샷 캡처 (auto_size: 다이어그램 실제 크기에 맞춰 캡처)
                captured_path = capture_screenshot(
                    html_path=html_path,
                    image_path=image_path,
                    auto_size=True,
                )

                return MockupResult(
                    backend=MockupBackend.MERMAID,
                    reason=analysis.reason,
                    html_path=html_path,
                    image_path=captured_path,
                    success=True,
                    message=self._create_mermaid_message(
                        mermaid_result.mermaid_code,
                        mermaid_result.diagram_type,
                        html_path,
                    ),
                    fallback_used=False,
                    mermaid_code=mermaid_result.mermaid_code,
                )
            else:
                # Mermaid 실패 시 HTML로 폴백
                return self._execute_backend(
                    backend=MockupBackend.HTML,
                    prompt=prompt,
                    options=options,
                    html_path=html_path,
                    image_path=image_path,
                    analysis=AnalysisResult(
                        backend=MockupBackend.HTML,
                        reason=SelectionReason.FALLBACK,
                        confidence=0.7,
                        details=f"Mermaid 실패 -> HTML 폴백: {mermaid_result.error_message}",
                    ),
                )

        if backend == MockupBackend.STITCH:
            # Stitch 시도
            stitch_result = self.stitch_adapter.generate_from_prompt(
                prompt, bnw=options.bnw if options else False
            )

            if stitch_result.success:
                html_content = stitch_result.html_content
            else:
                # 폴백 처리
                fallback_result = self.fallback_handler.handle_failure(
                    original_backend=backend,
                    error_message=stitch_result.error_message,
                    prompt=prompt,
                    options=options,
                )

                if fallback_result.should_fallback:
                    # HTML로 폴백
                    html_result = self.html_adapter.generate_from_prompt(prompt, options=options)
                    if html_result.success:
                        html_content = html_result.html_content
                        fallback_used = True
                        final_backend = MockupBackend.HTML
                        final_reason = SelectionReason.FALLBACK
                        # 경로 업데이트 (suffix 제거)
                        html_path, image_path = get_output_paths(
                            name=self._extract_name(prompt),
                            prd=options.prd,
                            suffix="",  # 폴백 시 suffix 없음
                        )
                    else:
                        return self._create_error_result(
                            html_path, image_path,
                            f"폴백도 실패: {html_result.error_message}"
                        )
                else:
                    return self._create_error_result(
                        html_path, image_path,
                        stitch_result.error_message or "Stitch 생성 실패"
                    )
        else:
            # HTML 생성
            html_result = self.html_adapter.generate_from_prompt(prompt, options=options)

            if html_result.success:
                html_content = html_result.html_content
            else:
                return self._create_error_result(
                    html_path, image_path,
                    html_result.error_message or "HTML 생성 실패"
                )

        # 4. HTML 저장
        screen_name = self._extract_name(prompt)
        saved_path = save_html(
            content=html_content,
            output_path=html_path,
            title=screen_name,
            description=prompt,
        )

        # 5. 스크린샷 캡처 (auto_size: 콘텐츠 크기에 맞춰 자동 캡처)
        captured_path = capture_screenshot(
            html_path=saved_path,
            image_path=image_path,
            auto_size=True,
        )

        # 6. 결과 생성
        success = saved_path.exists() and (captured_path is not None)

        return MockupResult(
            backend=final_backend,
            reason=final_reason,
            html_path=html_path,
            image_path=captured_path,  # 실제 캡처된 경로 (실패 시 None → embedder HTML 폴백)
            success=success,
            message=self._create_message(
                backend=final_backend,
                reason=final_reason,
                html_path=html_path,
                image_path=captured_path,
                success=success,
                fallback_used=fallback_used,
            ),
            fallback_used=fallback_used,
        )

    def _extract_name(self, prompt: str) -> str:
        """프롬프트에서 화면 이름 추출"""
        import re
        parts = re.split(r'\s*[-:]\s*', prompt, maxsplit=1)
        return parts[0].strip()

    def _create_error_result(
        self,
        html_path: Path,
        image_path: Path,
        error_message: str,
    ) -> MockupResult:
        """에러 결과 생성"""
        return MockupResult(
            backend=MockupBackend.HTML,
            reason=SelectionReason.DEFAULT,
            html_path=html_path,
            image_path=image_path,
            success=False,
            message=f"❌ 오류: {error_message}",
            fallback_used=False,
        )

    def _create_mermaid_message(
        self,
        mermaid_code: str,
        diagram_type: str,
        md_path: Path,
    ) -> str:
        """Mermaid 결과 메시지 생성"""
        lines = [
            f"📊 선택: Mermaid {diagram_type} (이유: 다이어그램 키워드 감지)",
            f"✅ 생성: {md_path}",
            "",
            "```mermaid",
            mermaid_code,
            "```",
        ]
        return "\n".join(lines)

    def _create_message(
        self,
        backend: MockupBackend,
        reason: SelectionReason,
        html_path: Path,
        image_path: Path,
        success: bool,
        fallback_used: bool,
    ) -> str:
        """결과 메시지 생성"""
        backend_info = self.analyzer.get_backend_info(backend)
        emoji = backend_info.get("emoji", "📄")
        name = backend_info.get("name", backend.value.upper())

        lines = []

        if fallback_used:
            lines.append("⚠️ Stitch API 실패 → HTML로 폴백")

        lines.append(f"{emoji} 선택: {name} (이유: {reason.value})")

        status = "✅" if success else "❌"
        lines.append(f"{status} 생성: {html_path}")
        lines.append(f"📸 캡처: {image_path}")

        return "\n".join(lines)
