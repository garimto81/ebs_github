"""
Google Stitch API 어댑터

Stitch API를 사용하여 고품질 AI 생성 UI 목업을 생성합니다.
"""

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import sys
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent.parent))

from lib.mockup_hybrid.stitch_client import StitchClient, get_stitch_client


@dataclass
class StitchGenerationResult:
    """Stitch 생성 결과"""
    success: bool
    html_content: str
    image_url: Optional[str] = None
    error_message: Optional[str] = None
    rate_limited: bool = False


class StitchAdapter:
    """Google Stitch API 어댑터"""

    def __init__(self, client: Optional[StitchClient] = None):
        """
        StitchAdapter 초기화

        Args:
            client: StitchClient 인스턴스 (없으면 기본 클라이언트 사용)
        """
        self.client = client or get_stitch_client()

    def is_available(self) -> bool:
        """Stitch API 사용 가능 여부"""
        return self.client.is_available()

    def is_rate_limited(self) -> bool:
        """Rate limit 초과 여부"""
        return self.client.is_rate_limited()

    def generate(
        self,
        screen_name: str,
        description: str = "",
        style: str = "modern",
        color_scheme: Optional[str] = None,
        bnw: bool = False,
    ) -> StitchGenerationResult:
        """
        Stitch API로 UI 생성

        Args:
            screen_name: 화면 이름
            description: 화면 설명
            style: 디자인 스타일
            color_scheme: 색상 스키마

        Returns:
            StitchGenerationResult 객체
        """
        if not self.is_available():
            return StitchGenerationResult(
                success=False,
                html_content="",
                error_message="Stitch API 키가 설정되지 않았습니다.",
            )

        if self.is_rate_limited():
            return StitchGenerationResult(
                success=False,
                html_content="",
                error_message="월간 사용 한도를 초과했습니다.",
                rate_limited=True,
            )

        # API 호출
        response = self.client.generate_ui(
            screen_name=screen_name,
            description=description or screen_name,
            style=style,
            color_scheme=color_scheme,
        )

        if response.success:
            return StitchGenerationResult(
                success=True,
                html_content=response.html_content or self._create_placeholder_html(screen_name, bnw=bnw),
                image_url=response.image_url,
            )
        else:
            return StitchGenerationResult(
                success=False,
                html_content="",
                error_message=response.error_message,
                rate_limited=response.rate_limited,
            )

    def generate_from_prompt(
        self,
        prompt: str,
        style: str = "modern",
        bnw: bool = False,
    ) -> StitchGenerationResult:
        """
        프롬프트에서 화면 정보 추출하여 생성

        Args:
            prompt: 사용자 프롬프트
            style: 디자인 스타일
            bnw: B&W 모드 여부

        Returns:
            StitchGenerationResult 객체
        """
        # 프롬프트 파싱
        parts = re.split(r'\s*[-:]\s*', prompt, maxsplit=1)
        screen_name = parts[0].strip()
        description = parts[1].strip() if len(parts) > 1 else ""

        return self.generate(
            screen_name=screen_name,
            description=description,
            style=style,
            bnw=bnw,
        )

    def _create_placeholder_html(self, title: str, bnw: bool = False) -> str:
        """Stitch 응답이 HTML을 포함하지 않을 경우 플레이스홀더 생성"""
        if bnw:
            bg_gradient = "linear-gradient(135deg, #e5e5e5 0%, #f8f8f8 100%)"
            badge_bg = "#1a1a1a"
            title_color = "#000"
            shadow = "0 20px 60px rgba(0,0,0,0.15)"
        else:
            bg_gradient = "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
            badge_bg = "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
            title_color = "#1a1a2e"
            shadow = "0 20px 60px rgba(0,0,0,0.3)"
        return f'''<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=800">
  <title>{title} - Stitch Generated</title>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: {bg_gradient};
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }}
    .container {{
      background: white;
      border-radius: 16px;
      box-shadow: {shadow};
      padding: 48px;
      text-align: center;
      max-width: 600px;
    }}
    .title {{
      font-size: 28px;
      font-weight: 700;
      color: {title_color};
      margin-bottom: 16px;
    }}
    .badge {{
      display: inline-block;
      background: {badge_bg};
      color: white;
      padding: 8px 16px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 24px;
    }}
    .placeholder {{
      background: #f8f9fa;
      border: 2px dashed #dee2e6;
      border-radius: 12px;
      padding: 60px 40px;
      color: #6c757d;
    }}
    .footer {{
      margin-top: 24px;
      font-size: 12px;
      color: #adb5bd;
    }}
  </style>
</head>
<body>
  <div class="container">
    <span class="badge">🤖 Stitch Generated</span>
    <h1 class="title">{title}</h1>
    <div class="placeholder">
      <p>AI가 생성한 고품질 UI 목업입니다.</p>
      <p style="margin-top: 12px; font-size: 14px;">
        실제 Stitch API 연동 시 이 영역에<br>
        AI가 생성한 UI가 표시됩니다.
      </p>
    </div>
    <p class="footer">Powered by Google Stitch API</p>
  </div>
</body>
</html>'''

    def get_usage_stats(self) -> dict:
        """사용량 통계 반환"""
        return self.client.get_usage_stats()
