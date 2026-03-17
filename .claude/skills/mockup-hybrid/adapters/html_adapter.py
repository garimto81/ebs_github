"""
HTML 와이어프레임 어댑터

기존 HTML 템플릿을 사용하여 와이어프레임 목업을 생성합니다.
"""

import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional
from datetime import datetime

_SKILL_ROOT = str(Path(__file__).resolve().parent.parent.parent.parent.parent)
if _SKILL_ROOT not in sys.path:
    sys.path.insert(0, _SKILL_ROOT)
from lib.mockup_hybrid import MockupOptions  # noqa: E402


@dataclass
class HTMLGenerationResult:
    """HTML 생성 결과"""
    success: bool
    html_content: str
    error_message: Optional[str] = None


class HTMLAdapter:
    """HTML 와이어프레임 어댑터"""

    DEFAULT_TEMPLATE_PATH = Path(__file__).parent.parent.parent.parent / "templates" / "mockup-wireframe.html"
    QUASAR_TEMPLATE_PATH = Path(__file__).parent.parent.parent.parent / "templates" / "mockup-quasar.html"
    QUASAR_WHITE_TEMPLATE_PATH = Path(__file__).parent.parent.parent.parent / "templates" / "mockup-quasar-white.html"

    def __init__(self, template_path: Optional[Path] = None):
        """
        HTMLAdapter 초기화

        Args:
            template_path: HTML 템플릿 경로
        """
        self.template_path = template_path or self.DEFAULT_TEMPLATE_PATH

    # WCAG AA 준수 B&W 팔레트 — Refined Minimal (Linear Style)
    BNW_PALETTE = {
        "text_primary": "#222326",      # Nordic Gray (Linear)
        "text_secondary": "#555555",    # secondary label
        "text_body": "#555555",         # body
        "text_muted": "#8a8a8a",        # muted caption
        "text_disabled": "#767676",     # WCAG AA 최소 대비율 4.54:1
        "border": "#e5e5e5",
        "bg_light": "#F4F5F8",          # Mercury White (Linear)
        "bg_white": "#ffffff",
    }

    def generate(
        self,
        screen_name: str,
        description: str = "",
        elements: Optional[list[str]] = None,
        layout: str = "1-column",
        options: Optional[MockupOptions] = None,
    ) -> HTMLGenerationResult:
        """
        HTML 와이어프레임 생성

        Args:
            screen_name: 화면 이름
            description: 화면 설명
            elements: 포함할 요소 목록 (header, sidebar, form, table, cards, modal)
            layout: 레이아웃 타입 (1-column, sidebar, 2-column)

        Returns:
            HTMLGenerationResult 객체
        """
        try:
            # 템플릿 로드 (스타일 기반 분기)
            if options and options.style == "quasar-white" and self.QUASAR_WHITE_TEMPLATE_PATH.exists():
                template = self.QUASAR_WHITE_TEMPLATE_PATH.read_text(encoding="utf-8")
            elif options and options.style == "quasar-white":
                template = self._get_quasar_white_default_template()
            elif options and options.style == "quasar" and self.QUASAR_TEMPLATE_PATH.exists():
                template = self.QUASAR_TEMPLATE_PATH.read_text(encoding="utf-8")
            elif options and options.style == "quasar":
                template = self._get_quasar_default_template()
            elif self.template_path.exists():
                template = self.template_path.read_text(encoding="utf-8")
            else:
                template = self._get_default_template()

            # 플레이스홀더 치환
            html = template.replace("{{title}}", screen_name)
            html = html.replace("{{description}}", description or screen_name)
            html = html.replace("{{date}}", datetime.now().strftime("%Y-%m-%d"))

            # B&W 팔레트 적용 (options.bnw=True 시, Quasar 스타일은 자체 색상 사용)
            if options and options.bnw and options.style not in ("quasar", "quasar-white"):
                html = self._apply_bnw_palette(html)

            # 요소 기반 커스터마이징
            if elements:
                html = self._customize_elements(html, elements)

            # 레이아웃 적용
            html = self._apply_layout(html, layout)

            return HTMLGenerationResult(
                success=True,
                html_content=html,
            )

        except Exception as e:
            return HTMLGenerationResult(
                success=False,
                html_content="",
                error_message=str(e),
            )

    def _get_default_template(self) -> str:
        """기본 템플릿 반환 — Refined Minimal (Linear Style)"""
        return '''<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=720">
  <title>{{title}} - Wireframe</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background: #F4F5F8;
      padding: 0;
      margin: 0;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }
    .container {
      width: auto;
      max-width: 720px;
      height: auto;
      max-height: 1280px;
      margin: 0;
      background: #ffffff;
      border: 1px solid #e5e5e5;
      border-radius: 12px;
      box-shadow:
        0 1px 1px rgba(0,0,0,0.03),
        0 3px 6px rgba(0,0,0,0.04),
        0 8px 16px rgba(0,0,0,0.03);
      overflow: hidden;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 32px;
      border-bottom: 1px solid #e5e5e5;
      background: #ffffff;
    }
    .logo-text {
      font-weight: 600;
      font-size: 0.8125rem;
      letter-spacing: -0.01em;
      color: #222326;
    }
    .header-meta {
      font-size: 0.75rem;
      font-weight: 400;
      color: #8a8a8a;
    }
    .content {
      padding: 48px 32px 64px;
    }
    .subtitle {
      font-size: 0.75rem;
      font-weight: 500;
      letter-spacing: 0.025em;
      text-transform: uppercase;
      color: #8a8a8a;
      margin-bottom: 12px;
    }
    .title {
      font-size: 1.875rem;
      font-weight: 600;
      color: #222326;
      letter-spacing: -0.025em;
      line-height: 1.2;
      margin-bottom: 16px;
    }
    .description {
      font-size: 0.9375rem;
      font-weight: 400;
      line-height: 1.5;
      color: #555555;
      margin-bottom: 48px;
      max-width: 560px;
    }
    .placeholder {
      border: 1px dashed #e5e5e5;
      padding: 48px 32px;
      background: #F4F5F8;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: flex-start;
    }
    .placeholder-label {
      font-size: 0.75rem;
      font-weight: 500;
      letter-spacing: 0.025em;
      text-transform: uppercase;
      color: #8a8a8a;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <span class="logo-text">Wireframe</span>
      <span class="header-meta">{{date}}</span>
    </div>
    <div class="content">
      <p class="subtitle">Mockup</p>
      <h1 class="title">{{title}}</h1>
      <p class="description">{{description}}</p>
      <div class="placeholder">
        <span class="placeholder-label">Content Area</span>
      </div>
    </div>
  </div>
</body>
</html>'''

    def _get_quasar_default_template(self) -> str:
        """Quasar UMD 인라인 폴백 템플릿 (CDN 파일 없을 시)"""
        return '''<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{title}} - Quasar Mockup</title>
  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/quasar@2/dist/quasar.prod.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/@quasar/extras@1/material-icons/material-icons.css" rel="stylesheet">
  <style>
    body { font-family: 'Roboto', sans-serif; margin: 0; padding: 0; background: #f5f5f5; }
    #q-app { width: auto; max-width: 720px; max-height: 1280px; margin: 0; overflow: auto; }
  </style>
</head>
<body>
  <div id="q-app">
    <q-layout view="hHh lpR fFf">
      <q-header elevated class="bg-primary text-white">
        <q-toolbar>
          <q-toolbar-title>{{title}}</q-toolbar-title>
        </q-toolbar>
      </q-header>
      <q-page-container>
        <q-page class="q-pa-md">
          <div class="text-h6 q-mb-md">{{description}}</div>
          <q-card class="q-mb-md">
            <q-card-section>
              <div class="text-h6">Content Area</div>
            </q-card-section>
            <q-card-section>
              <div class="text-body1">Replace with actual content.</div>
            </q-card-section>
          </q-card>
        </q-page>
      </q-page-container>
      <q-footer bordered class="bg-white text-grey-6 text-center q-pa-sm" style="font-size: 11px;">
        Generated by Claude Code | {{date}}
      </q-footer>
    </q-layout>
  </div>
  <script src="https://cdn.jsdelivr.net/npm/vue@3/dist/vue.global.prod.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/quasar@2/dist/quasar.umd.prod.js"></script>
  <script>
    const app = Vue.createApp({ data() { return {} } })
    app.use(Quasar)
    app.mount('#q-app')
  </script>
</body>
</html>'''

    def _get_quasar_white_default_template(self) -> str:
        """Quasar White Minimal 폴백 템플릿 (CDN 파일 없을 시)"""
        return '''<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{title}} - Quasar White Mockup</title>
  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/quasar@2/dist/quasar.prod.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/@quasar/extras@1/material-icons/material-icons.css" rel="stylesheet">
  <style>
    :root { --q-primary: #374151; --q-secondary: #6b7280; }
    body { font-family: 'Roboto', sans-serif; margin: 0; padding: 0; background: #ffffff; }
    #q-app { width: auto; max-width: 720px; max-height: 1280px; margin: 0; overflow: auto; }
    .q-layout { min-height: auto !important; }
    .q-page-container { min-height: auto !important; padding-top: 50px !important; }
    .q-page { min-height: auto !important; }
    .q-header { position: relative !important; }
  </style>
</head>
<body>
  <div id="q-app">
    <q-layout view="hHh lpR fFf">
      <q-header class="bg-white text-dark" style="border-bottom: 1px solid #e5e7eb">
        <q-toolbar>
          <q-toolbar-title>{{title}}</q-toolbar-title>
        </q-toolbar>
      </q-header>
      <q-page-container>
        <q-page class="q-pa-md">
          <div class="text-h6 q-mb-md">{{description}}</div>
          <q-card flat bordered class="q-mb-md">
            <q-card-section>
              <div class="text-h6">Content Area</div>
            </q-card-section>
            <q-card-section>
              <div class="text-body1">Replace with actual content.</div>
            </q-card-section>
            <q-card-actions>
              <q-btn flat color="grey-8" label="Action"></q-btn>
            </q-card-actions>
          </q-card>
        </q-page>
      </q-page-container>
      <q-footer bordered class="bg-white text-grey-6 text-center q-pa-sm" style="font-size: 11px; border-top: 1px solid #e5e7eb">
        Generated by Claude Code | {{date}}
      </q-footer>
    </q-layout>
  </div>
  <script src="https://cdn.jsdelivr.net/npm/vue@3/dist/vue.global.prod.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/quasar@2/dist/quasar.umd.prod.js"></script>
  <script>
    const app = Vue.createApp({ data() { return {} } })
    app.use(Quasar)
    app.mount('#q-app')
  </script>
</body>
</html>'''

    def _apply_bnw_palette(self, html: str) -> str:
        """B&W 팔레트 강제 적용 — Refined Minimal 색상 정규화"""
        p = self.BNW_PALETTE
        # 순수 검정 → Nordic Gray
        html = html.replace("color: #000", f'color: {p["text_primary"]}')
        html = html.replace("color:#000", f'color:{p["text_primary"]}')
        # #1a1a1a → text_primary
        html = html.replace("#1a1a1a", p["text_primary"])
        # #2d2d2d → text_body
        html = html.replace("#2d2d2d", p["text_body"])
        # #999 → muted
        html = html.replace("#999", p["text_muted"])
        # #666 → muted
        html = html.replace("#666", p["text_muted"])
        # #f8f8f8 → Mercury White
        html = html.replace("#f8f8f8", p["bg_light"])
        # 비 grayscale rgba는 건드리지 않음 (3-layer shadow 패턴 보존)
        # 단, 높은 opacity(>0.1) rgba만 낮춤
        html = re.sub(
            r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*(0\.[1-9]\d*|[1-9][\d.]*)\)',
            lambda m: f'rgba({m.group(1)},{m.group(2)},{m.group(3)},0.06)'
            if float(m.group(4)) > 0.1 else m.group(0),
            html,
        )
        return html

    def _customize_elements(self, html: str, elements: list[str]) -> str:
        """요소 기반 커스터마이징"""
        # 현재는 기본 템플릿 유지
        # 향후 요소별 HTML 블록 주입 가능
        return html

    def _apply_layout(self, html: str, layout: str) -> str:
        """레이아웃 적용"""
        # 현재는 기본 레이아웃 유지
        # 향후 레이아웃별 CSS/HTML 변경 가능
        return html

    def generate_from_prompt(
        self,
        prompt: str,
        options: Optional[MockupOptions] = None,
    ) -> HTMLGenerationResult:
        """
        프롬프트에서 화면 정보 추출하여 생성

        Args:
            prompt: 사용자 프롬프트
            options: 목업 옵션 (B&W 등)

        Returns:
            HTMLGenerationResult 객체
        """
        # 간단한 프롬프트 파싱
        # "화면명 - 설명" 또는 "화면명: 설명" 형식 지원
        parts = re.split(r'\s*[-:]\s*', prompt, maxsplit=1)
        screen_name = parts[0].strip()
        description = parts[1].strip() if len(parts) > 1 else ""

        # 요소 감지 (간단한 키워드 기반)
        elements = []
        prompt_lower = prompt.lower()

        if any(k in prompt_lower for k in ["폼", "form", "입력", "로그인", "login"]):
            elements.append("form")
        if any(k in prompt_lower for k in ["테이블", "table", "목록", "list"]):
            elements.append("table")
        if any(k in prompt_lower for k in ["카드", "card", "그리드", "grid"]):
            elements.append("cards")
        if any(k in prompt_lower for k in ["사이드바", "sidebar", "메뉴"]):
            elements.append("sidebar")

        return self.generate(
            screen_name=screen_name,
            description=description,
            elements=elements if elements else None,
            options=options,
        )
