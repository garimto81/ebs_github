"""Ollama Gemma client — timeout/OOM/JSON-parse safe."""
from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any

from . import config


class GemmaError(Exception):
    pass


class GemmaTimeout(GemmaError):
    pass


class GemmaOOM(GemmaError):
    pass


class GemmaParseError(GemmaError):
    pass


@dataclass
class GemmaResponse:
    text: str
    raw: dict
    model: str
    elapsed_ms: int


def _http_post_json(url: str, body: dict, timeout: int) -> dict:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url, data=data, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def generate(
    prompt: str,
    *,
    model: str | None = None,
    system: str | None = None,
    json_mode: bool = False,
    temperature: float = 0.0,
    timeout: int | None = None,
    retry: int | None = None,
) -> GemmaResponse:
    model = model or config.CIA_MODEL
    timeout = timeout or config.LLM_TIMEOUT_SEC
    retry = retry if retry is not None else config.LLM_RETRY

    body: dict[str, Any] = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "keep_alive": "20m",
        "options": {"temperature": temperature, "num_predict": 1024},
    }
    if system:
        body["system"] = system
    if json_mode:
        body["format"] = "json"

    last_err: Exception | None = None
    for attempt in range(retry + 1):
        t0 = time.time()
        try:
            data = _http_post_json(config.OLLAMA_GENERATE, body, timeout)
            return GemmaResponse(
                text=data.get("response", ""),
                raw=data,
                model=model,
                elapsed_ms=int((time.time() - t0) * 1000),
            )
        except TimeoutError:
            last_err = GemmaTimeout(f"timeout {timeout}s on {model}")
        except urllib.error.HTTPError as e:
            try:
                msg = e.read().decode("utf-8", errors="ignore")
            except Exception:
                msg = ""
            if "out of memory" in msg.lower():
                last_err = GemmaOOM(f"OOM: {msg[:200]}")
                if model == config.CIA_MODEL and attempt == 0:
                    model = config.INTENT_MODEL
                    body["model"] = model
                    continue
            elif "model" in msg.lower() and "not found" in msg.lower():
                last_err = GemmaError(f"model missing: {model}: {msg[:200]}")
                break
            else:
                last_err = GemmaError(f"HTTP {e.code}: {msg[:200]}")
        except urllib.error.URLError as e:
            last_err = GemmaError(f"URL error: {e}")
        except Exception as e:
            last_err = GemmaError(f"unexpected: {type(e).__name__}: {e}")
        time.sleep(1.5 * (attempt + 1))

    raise last_err if last_err else GemmaError("unknown")


def parse_json(text: str) -> dict:
    """Tolerant JSON parser — strips fences, prose preamble."""
    if text is None:
        raise GemmaParseError("None response")
    text = text.strip()
    if not text:
        raise GemmaParseError("empty response")

    if text.startswith("```"):
        end = text.find("```", 3)
        if end > 0:
            inner = text[3:end].strip()
            if inner.startswith("json"):
                inner = inner[4:].strip()
            text = inner

    s = text.find("{")
    e = text.rfind("}")
    if s < 0 or e < 0 or e <= s:
        raise GemmaParseError(f"no JSON object: head={text[:120]}")
    candidate = text[s : e + 1]
    try:
        return json.loads(candidate)
    except json.JSONDecodeError as ex:
        raise GemmaParseError(f"invalid JSON: {ex}; head={candidate[:200]}")


def list_models() -> list[str]:
    try:
        with urllib.request.urlopen(config.OLLAMA_TAGS, timeout=5) as r:
            data = json.loads(r.read())
            return [m["name"] for m in data.get("models", [])]
    except Exception:
        return []


def health() -> bool:
    return bool(list_models())
