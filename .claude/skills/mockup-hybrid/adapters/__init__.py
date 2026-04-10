"""
Mockup Hybrid Adapters 모듈

HTML 및 Stitch 백엔드 어댑터를 제공합니다.
"""

from .html_adapter import HTMLAdapter, HTMLGenerationResult
from .stitch_adapter import StitchAdapter, StitchGenerationResult

__all__ = [
    "HTMLAdapter",
    "HTMLGenerationResult",
    "StitchAdapter",
    "StitchGenerationResult",
]
