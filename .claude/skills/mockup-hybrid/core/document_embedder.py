"""
문서 임베더 - 생성된 목업을 원본 문서에 삽입

Mermaid → 인라인 코드 블록, HTML → 이미지 참조로 삽입합니다.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import sys
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent.parent))

from lib.mockup_hybrid import MockupBackend, MockupResult
from .document_scanner import SectionScanResult


@dataclass
class EmbedResult:
    """삽입 결과"""
    section_heading: str
    backend: MockupBackend
    success: bool
    message: str


class DocumentEmbedder:
    """문서에 목업 결과를 삽입"""

    def embed(
        self,
        doc_path: Path,
        section: SectionScanResult,
        mockup_result: MockupResult,
    ) -> EmbedResult:
        """
        목업 결과를 문서의 해당 섹션 아래에 삽입

        Args:
            doc_path: 원본 문서 경로
            section: 스캔된 섹션 정보
            mockup_result: 생성된 목업 결과

        Returns:
            EmbedResult 객체
        """
        try:
            content = doc_path.read_text(encoding="utf-8")
            lines = content.split("\n")

            # 삽입할 블록 생성
            embed_block = self._create_embed_block(mockup_result, doc_path)
            if not embed_block:
                return EmbedResult(
                    section_heading=section.heading,
                    backend=mockup_result.backend,
                    success=False,
                    message="삽입할 블록 생성 실패",
                )

            # 삽입 위치 결정: 섹션 헤딩 바로 다음 줄
            insert_line = section.line_start + 1

            # 빈 줄이 있으면 그 다음에 삽입
            while insert_line < len(lines) and lines[insert_line].strip() == "":
                insert_line += 1

            # 삽입
            embed_lines = ["", embed_block, ""]
            lines[insert_line:insert_line] = embed_lines

            # 저장
            doc_path.write_text("\n".join(lines), encoding="utf-8")

            return EmbedResult(
                section_heading=section.heading,
                backend=mockup_result.backend,
                success=True,
                message=f"삽입 완료 (line {insert_line})",
            )

        except Exception as e:
            return EmbedResult(
                section_heading=section.heading,
                backend=mockup_result.backend,
                success=False,
                message=f"삽입 실패: {e}",
            )

    def _create_embed_block(
        self,
        mockup_result: MockupResult,
        doc_path: Path,
    ) -> Optional[str]:
        """목업 결과에서 삽입할 블록 생성"""
        if mockup_result.backend == MockupBackend.MERMAID:
            return self._mermaid_block(mockup_result)
        elif mockup_result.backend in (MockupBackend.HTML, MockupBackend.STITCH):
            return self._image_block(mockup_result, doc_path)
        return None

    def _mermaid_block(self, result: MockupResult) -> str:
        """Mermaid 인라인 블록"""
        if result.mermaid_code:
            return f"```mermaid\n{result.mermaid_code}\n```"
        return ""

    def _image_block(self, result: MockupResult, doc_path: Path) -> str:
        """이미지 참조 블록"""
        # PNG 스크린샷이 있으면 이미지로 삽입
        if result.image_path and result.image_path.exists():
            # 문서 위치 기준 상대 경로 계산
            try:
                rel_path = result.image_path.relative_to(doc_path.parent)
            except ValueError:
                rel_path = result.image_path
            # 항상 forward slash 사용 (markdown 호환)
            rel_str = str(rel_path).replace("\\", "/")
            name = result.image_path.stem
            return f"![{name}]({rel_str})"
        # PNG 캡처 실패 시 HTML 파일 링크로 폴백 (마크다운 미업데이트 방지)
        if result.html_path and result.html_path.exists():
            try:
                rel_path = result.html_path.relative_to(doc_path.parent)
            except ValueError:
                rel_path = result.html_path
            rel_str = str(rel_path).replace("\\", "/")
            name = result.html_path.stem
            return f"[{name} 목업]({rel_str})"
        return ""

    def embed_batch(
        self,
        doc_path: Path,
        results: list[tuple[SectionScanResult, MockupResult]],
    ) -> list[EmbedResult]:
        """
        여러 결과를 한꺼번에 삽입 (역순으로 처리하여 라인 번호 유지)

        Args:
            doc_path: 원본 문서 경로
            results: (섹션, 목업결과) 튜플 리스트

        Returns:
            EmbedResult 리스트
        """
        # 역순 정렬 (뒤에서부터 삽입해야 앞쪽 라인 번호가 밀리지 않음)
        sorted_results = sorted(results, key=lambda x: x[0].line_start, reverse=True)

        embed_results = []
        for section, mockup_result in sorted_results:
            result = self.embed(doc_path, section, mockup_result)
            embed_results.append(result)

        # 원래 순서로 되돌림
        embed_results.reverse()
        return embed_results
