#!/usr/bin/env python3
"""Generate annotated overlay images for PokerGFX UI Analysis and EBS Console.

Usage:
  python generate_annotations.py                          # Normal (auto-snap + empty check)
  python generate_annotations.py --no-snap                # Normal without edge snapping
  python generate_annotations.py --calibrate              # Calibrate + save JSON sidecar
  python generate_annotations.py --calibrate --target 02  # Calibrate single image
  python generate_annotations.py --debug                  # Debug overlay with grid
  python generate_annotations.py --debug --target 02      # Debug single image
  python generate_annotations.py --ocr                    # OCR-based precision calibration
  python generate_annotations.py --ocr --target 04        # OCR calibration for single image
  python generate_annotations.py --ebs                    # EBS Console tab annotation
  python generate_annotations.py --ebs --target sources   # Single EBS tab
  python generate_annotations.py --ebs --calibrate        # EBS with auto-calibration

Strategy: Contrast Edge Detection + Auto-Calibration
- Normal mode: auto-snaps box edges to nearest contrast boundaries (±2px)
- Empty box detection: warns when a box covers uniform-color space
- Calibrate mode: saves calibrated coordinates to JSON sidecar file
- Debug mode: shows detected edges and coordinate labels
- OCR mode: Tesseract OCR detects text regions, refines box coords, then applies edge-snap
"""
import argparse
import json
import os
import sys
from PIL import Image, ImageDraw, ImageFont

try:
    import pytesseract
    pytesseract.pytesseract.tesseract_cmd = r'C:/Users/AidenKim/scoop/shims/tesseract.exe'
    # Set TESSDATA_PREFIX so Tesseract can find language files installed via scoop
    os.environ.setdefault(
        'TESSDATA_PREFIX',
        r'C:\Users\AidenKim\scoop\persist\tesseract\tessdata'
    )
    TESSERACT_AVAILABLE = True
except ImportError:
    TESSERACT_AVAILABLE = False

try:
    from playwright.sync_api import sync_playwright
    PLAYWRIGHT_AVAILABLE = True
except ImportError:
    PLAYWRIGHT_AVAILABLE = False

INPUT_DIR = "C:/claude/ebs/images/pokerGFX"
OUTPUT_DIR = "C:/claude/ebs/docs/01_PokerGFX_Analysis/02_Annotated_ngd"
CROP_DIR = "C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd"

DELTA_GUARD = {
    'dy_max': 12,   # y 이동 최대 (행 겹침 방지)
    'dh_max': 20,   # 높이 변화 최대 (오버 확장 방지)
    'dx_max': 20,   # x 이동 최대
    'dw_max': 25,   # 너비 변화 최대
}

# Font setup
try:
    font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 13)
except Exception:
    font = ImageFont.load_default()

try:
    font_small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 10)
except Exception:
    font_small = ImageFont.load_default()

RED = (220, 30, 30)
GREEN = (30, 160, 30)
BLUE = (30, 100, 220)

DROP_OVERLAY_COLOR = (255, 0, 0)   # X선용 순수 빨강
DROP_ALPHA = 80                     # 31% 불투명도 (기존 22의 약 3.6배)
DROP_LINE_WIDTH = 3                 # X 선 굵기


# ============================================================
# EDGE DETECTION & AUTO-CALIBRATION
# ============================================================

def find_h_edge(pixels, img_w, img_h, y_est, x_start, x_end, search_range=20):
    """Find nearest horizontal contrast edge near y_est.

    Scans rows within ±search_range of y_est, comparing each row's pixels
    with the row above. Returns the row with highest average contrast.
    Contrast = sum(|R1-R2| + |G1-G2| + |B1-B2|) per pixel pair.
    """
    x_end = min(x_end, img_w)
    best_y = y_est
    best_score = 0.0

    for y in range(max(1, y_est - search_range),
                   min(img_h - 1, y_est + search_range + 1)):
        score = 0.0
        n = 0
        for x in range(max(0, x_start), x_end, 3):
            r1, g1, b1 = pixels[x, y - 1][:3]
            r2, g2, b2 = pixels[x, y][:3]
            score += abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
            n += 1
        if n > 0:
            avg = score / n
            if avg > best_score:
                best_score = avg
                best_y = y

    # Only snap if contrast is significant (threshold=25)
    return best_y if best_score > 25 else y_est


def find_v_edge(pixels, img_w, img_h, x_est, y_start, y_end, search_range=20):
    """Find nearest vertical contrast edge near x_est.

    Same logic as find_h_edge but for vertical edges (column-to-column).
    """
    y_end = min(y_end, img_h)
    best_x = x_est
    best_score = 0.0

    for x in range(max(1, x_est - search_range),
                   min(img_w - 1, x_est + search_range + 1)):
        score = 0.0
        n = 0
        for y in range(max(0, y_start), y_end, 3):
            r1, g1, b1 = pixels[x - 1, y][:3]
            r2, g2, b2 = pixels[x, y][:3]
            score += abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
            n += 1
        if n > 0:
            avg = score / n
            if avg > best_score:
                best_score = avg
                best_x = x

    return best_x if best_score > 25 else x_est


def auto_calibrate(img, boxes):
    """Auto-calibrate box positions using contrast edge detection.

    For each box, snaps all 4 edges to the nearest high-contrast boundary
    within a search range. Returns calibrated boxes with delta info.
    """
    pixels = img.load()
    w, h = img.size
    calibrated = []

    for box in boxes:
        x, y, bw, bh = box['rect']

        # Skip edge snapping for boxes with no_snap flag
        if box.get('no_snap'):
            new_box = dict(box)
            new_box['rect'] = (x, y, bw, bh)
            new_box['_original'] = (x, y, bw, bh)
            new_box['_delta'] = (0, 0, 0, 0)
            calibrated.append(new_box)
            continue

        # Snap top edge: scan horizontal contrast in the box's X range
        new_y = find_h_edge(pixels, w, h, y, x, x + bw)
        # Snap bottom edge
        new_y2 = find_h_edge(pixels, w, h, y + bh, x, x + bw)
        # Snap left edge: scan vertical contrast in the box's Y range
        new_x = find_v_edge(pixels, w, h, x, y, y + bh)
        # Snap right edge
        new_x2 = find_v_edge(pixels, w, h, x + bw, y, y + bh)

        new_bw = new_x2 - new_x
        new_bh = new_y2 - new_y

        # Guard: keep original if result is unreasonable
        if new_bw < 10:
            new_bw = bw
            new_x = x
        if new_bh < 8:
            new_bh = bh
            new_y = y

        new_box = dict(box)
        new_box['rect'] = (new_x, new_y, new_bw, new_bh)
        new_box['_original'] = (x, y, bw, bh)
        dx, dy, dw, dh = new_x - x, new_y - y, new_bw - bw, new_bh - bh
        new_box['_delta'] = (dx, dy, dw, dh)
        calibrated.append(new_box)

    # Prevent calibrated boxes from overlapping each other
    for i in range(len(calibrated)):
        for j in range(i + 1, len(calibrated)):
            ri = calibrated[i]['rect']
            rj = calibrated[j]['rect']
            # AABB overlap test
            if (ri[0] < rj[0] + rj[2] and ri[0] + ri[2] > rj[0] and
                    ri[1] < rj[1] + rj[3] and ri[1] + ri[3] > rj[1]):
                di = calibrated[i].get('_delta', (0, 0, 0, 0))
                dj = calibrated[j].get('_delta', (0, 0, 0, 0))
                # Revert the box that moved more
                if sum(abs(d) for d in di) >= sum(abs(d) for d in dj):
                    orig = calibrated[i]['_original']
                    calibrated[i]['rect'] = orig
                    calibrated[i]['_delta'] = (0, 0, 0, 0)
                else:
                    orig = calibrated[j]['_original']
                    calibrated[j]['rect'] = orig
                    calibrated[j]['_delta'] = (0, 0, 0, 0)

    return calibrated


def ocr_calibrate(img, boxes):
    """Refine box positions using Tesseract OCR text detection.

    For each annotation box:
    1. Run pytesseract.image_to_data() on the full image with confidence > 30 filter.
    2. Find all OCR word bounding boxes that overlap or are contained within the annotation box.
    3. If matching OCR text found, expand/adjust the annotation box to tightly fit
       the union bounding box of all matching OCR text regions.
    4. Fall back to original box if no OCR text found in region.

    Returns calibrated boxes with '_ocr_text', '_ocr_count', '_delta' metadata.
    Requires TESSERACT_AVAILABLE = True (pytesseract installed + tesseract binary).
    """
    if not TESSERACT_AVAILABLE:
        print("  [OCR] pytesseract not available, skipping OCR calibration")
        return [dict(b) for b in boxes]

    img_w, img_h = img.size

    # Run OCR once on the full image
    ocr_data = pytesseract.image_to_data(
        img,
        output_type=pytesseract.Output.DICT,
        lang='eng',
        config='--psm 11'  # sparse text: find as many text regions as possible
    )

    # Build list of high-confidence word bounding boxes
    word_boxes = []
    n_words = len(ocr_data['text'])
    for i in range(n_words):
        conf = int(ocr_data['conf'][i])
        text = ocr_data['text'][i].strip()
        if conf < 30 or not text:
            continue
        wx = ocr_data['left'][i]
        wy = ocr_data['top'][i]
        ww = ocr_data['width'][i]
        wh = ocr_data['height'][i]
        word_boxes.append({
            'text': text,
            'conf': conf,
            'x': wx, 'y': wy, 'w': ww, 'h': wh,
        })

    print(f"  [OCR] Detected {len(word_boxes)} high-confidence words (conf>30)")

    calibrated = []
    adjusted_count = 0

    for box in boxes:
        if box.get('no_snap'):
            calibrated.append(dict(box, _delta=(0, 0, 0, 0), _ocr_text='', _ocr_count=0))
            continue
        x, y, bw, bh = box['rect']
        box_x2 = x + bw
        box_y2 = y + bh

        # Find OCR words that overlap with this annotation box
        # Overlap: word center must be inside the box (more robust than full containment)
        matched = []
        for wb in word_boxes:
            wx, wy, ww, wh = wb['x'], wb['y'], wb['w'], wb['h']
            # Word center
            cx = wx + ww // 2
            cy = wy + wh // 2
            if x <= cx <= box_x2 and y <= cy <= box_y2:
                matched.append(wb)

        new_box = dict(box)
        new_box['_original'] = (x, y, bw, bh)

        if matched:
            # Compute union bounding box of all matched OCR word regions
            min_x = min(wb['x'] for wb in matched)
            min_y = min(wb['y'] for wb in matched)
            max_x = max(wb['x'] + wb['w'] for wb in matched)
            max_y = max(wb['y'] + wb['h'] for wb in matched)

            # Add small padding (2px) around OCR bounding box
            pad = 2
            min_x = max(0, min_x - pad)
            min_y = max(0, min_y - pad)
            max_x = min(img_w, max_x + pad)
            max_y = min(img_h, max_y + pad)

            # Only adjust if the OCR region fits within a reasonable expansion
            # (guard against OCR picking up text outside the actual UI element)
            # Allow expansion of up to 30px in any direction
            max_expand = 30
            new_x = max(x - max_expand, min(x, min_x))
            new_y = max(y - max_expand, min(y, min_y))
            new_x2 = min(box_x2 + max_expand, max(box_x2, max_x))
            new_y2 = min(box_y2 + max_expand, max(box_y2, max_y))

            new_bw = new_x2 - new_x
            new_bh = new_y2 - new_y

            # Guard: reject if result is too small or too large
            if new_bw >= 8 and new_bh >= 6:
                dx = new_x - x
                dy = new_y - y
                dw = new_bw - bw
                dh = new_bh - bh

                # ── Adaptive Delta Guard ───────────────────────────────────
                guard_violated = (
                    abs(dy) > DELTA_GUARD['dy_max'] or
                    abs(dh) > DELTA_GUARD['dh_max'] or
                    abs(dx) > DELTA_GUARD['dx_max'] or
                    abs(dw) > DELTA_GUARD['dw_max']
                )
                if guard_violated:
                    new_box['rect'] = (x, y, bw, bh)
                    new_box['_delta'] = (0, 0, 0, 0)
                    new_box['_ocr_text'] = ' | '.join(wb['text'] for wb in matched[:5])
                    new_box['_ocr_count'] = len(matched)
                    new_box['_auto_protected'] = True
                    print(f"  [OCR] [{box['label']:>3}] PROTECTED d({dx:+d},{dy:+d},{dw:+d},{dh:+d})")
                    calibrated.append(new_box)
                    continue
                # ── Guard 통과 시 기존 적용 ────────────────────────────────

                new_box['rect'] = (new_x, new_y, new_bw, new_bh)
                new_box['_delta'] = (dx, dy, dw, dh)
                new_box['_ocr_text'] = ' | '.join(wb['text'] for wb in matched[:5])
                new_box['_ocr_count'] = len(matched)

                if any(d != 0 for d in (dx, dy, dw, dh)):
                    adjusted_count += 1
                    ocr_texts = ' '.join(wb['text'] for wb in matched[:3])
                    # Encode safely for terminals with limited charset (e.g. cp949)
                    safe_text = ocr_texts.encode('ascii', errors='replace').decode('ascii')
                    print(f"  [OCR] [{box['label']:>3}] d({dx:+d},{dy:+d},{dw:+d},{dh:+d})"
                          f"  text: \"{safe_text}\"")
            else:
                new_box['_delta'] = (0, 0, 0, 0)
                new_box['_ocr_text'] = ''
                new_box['_ocr_count'] = 0
        else:
            new_box['_delta'] = (0, 0, 0, 0)
            new_box['_ocr_text'] = ''
            new_box['_ocr_count'] = 0

        calibrated.append(new_box)

    print(f"  [OCR] {adjusted_count}/{len(boxes)} boxes adjusted by OCR")
    return calibrated


def check_empty_boxes(img, boxes, variance_threshold=15):
    """Check if any box covers mostly uniform/empty space.

    Samples pixels inside each box and calculates average color deviation.
    Low deviation = likely empty space, separator, or uniform background.
    Returns list of warning dicts: {'label', 'rect', 'variance', 'avg_color'}.
    """
    pixels = img.load()
    w_img, h_img = img.size
    warnings = []

    for box in boxes:
        x, y, bw, bh = box['rect']
        label = box['label']

        # Skip boxes marked no_snap (solid-colour swatches, dark checkboxes)
        if box.get('no_snap'):
            continue

        # Skip very small boxes (checkboxes, dismiss buttons)
        if bw < 20 or bh < 10:
            continue

        # Sample pixels in a grid inside the box (avoid border pixels)
        samples = []
        step_x = max(1, bw // 8)
        step_y = max(1, bh // 6)
        for sy in range(y + 3, min(y + bh - 3, h_img), step_y):
            for sx in range(x + 3, min(x + bw - 3, w_img), step_x):
                r, g, b = pixels[sx, sy][:3]
                samples.append((r, g, b))

        if len(samples) < 4:
            continue

        # Calculate average color deviation
        avg_r = sum(s[0] for s in samples) / len(samples)
        avg_g = sum(s[1] for s in samples) / len(samples)
        avg_b = sum(s[2] for s in samples) / len(samples)

        variance = sum(
            abs(s[0] - avg_r) + abs(s[1] - avg_g) + abs(s[2] - avg_b)
            for s in samples
        ) / len(samples)

        if variance < variance_threshold:
            avg_color = f"rgb({int(avg_r)},{int(avg_g)},{int(avg_b)})"
            warnings.append({
                'label': label,
                'rect': (x, y, bw, bh),
                'variance': round(variance, 1),
                'avg_color': avg_color,
            })

    return warnings


def detect_all_h_separators(img, y_start=0, y_end=None, min_ratio=0.5):
    """Detect all horizontal dark lines (separators) in image."""
    if y_end is None:
        y_end = img.height
    pixels = img.load()
    w = img.width
    separators = []

    for y in range(y_start, min(y_end, img.height)):
        dark = 0
        total = 0
        for x in range(5, w - 5, 2):
            r, g, b = pixels[x, y][:3]
            if r < 80 and g < 80 and b < 80:
                dark += 1
            total += 1
        if total > 0 and dark / total >= min_ratio:
            separators.append(y)

    # Merge adjacent (within 2px)
    merged = []
    for y in separators:
        if merged and y - merged[-1] <= 2:
            pass  # skip adjacent
        else:
            merged.append(y)
    return merged


# ============================================================
# CROP FUNCTION
# ============================================================

def crop_boxes(img, boxes, output_dir, name, padding=8):
    """Crop each annotated box region from original image with padding.

    Uses calibrated coordinates. Clamps to image boundaries.
    Adds a label watermark (red background, white text) at top-left.
    Returns count of crops generated.
    """
    os.makedirs(output_dir, exist_ok=True)
    w, h = img.size
    count = 0

    for box in boxes:
        x, y, bw, bh = box['rect']
        label = str(box['label'])

        # Apply padding + clamp to image bounds
        pad = padding
        x1 = max(0, x - pad)
        y1 = max(0, y - pad)
        x2 = min(w, x + bw + pad)
        y2 = min(h, y + bh + pad)

        # Minimum size guard: expand padding if crop is too small
        if (x2 - x1) < 20 or (y2 - y1) < 15:
            pad = 16
            x1 = max(0, x - pad)
            y1 = max(0, y - pad)
            x2 = min(w, x + bw + pad)
            y2 = min(h, y + bh + pad)

        cropped = img.crop((x1, y1, x2, y2))

        # Label watermark at top-left corner
        draw = ImageDraw.Draw(cropped)
        badge_w = max(22, len(label) * 7 + 8)
        draw.rectangle([0, 0, badge_w, 16], fill=RED)
        draw.text((4, 1), label, fill='white', font=font_small)

        fname = f"{name}-crop-{label}.png"
        cropped.save(os.path.join(output_dir, fname), quality=95)
        count += 1

    return count


# ============================================================
# DRAWING FUNCTIONS
# ============================================================

def draw_boxes(img, boxes, default_color=RED):
    """Draw annotation boxes with external labels on image."""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for box in boxes:
        x, y, w, h = box['rect']
        label = str(box['label'])
        c = box.get('color', default_color)
        is_drop = box.get('is_drop', False)

        # Semi-transparent fill
        fill_alpha = DROP_ALPHA if is_drop else 22
        draw.rectangle([x + 2, y + 2, x + w - 2, y + h - 2], fill=(*c, fill_alpha))
        # Border
        draw.rectangle([x, y, x + w, y + h], outline=c, width=2)

        # Drop: 대각선 X 마킹 + [DROP] 라벨 접두사
        if is_drop:
            pad = 6
            draw.line([(x + pad, y + pad), (x + w - pad, y + h - pad)],
                      fill=DROP_OVERLAY_COLOR, width=DROP_LINE_WIDTH)
            draw.line([(x + w - pad, y + pad), (x + pad, y + h - pad)],
                      fill=DROP_OVERLAY_COLOR, width=DROP_LINE_WIDTH)
            label = f'[DROP] {label}'

        # Label badge - positioned above the box
        bbox = draw.textbbox((0, 0), label, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        pad_x, pad_y = 5, 2
        badge_w = tw + pad_x * 2
        badge_h = th + pad_y * 2 + 2

        # Label position: 'top' (default), 'right', 'bottom'
        label_pos = box.get('label_pos', 'top')

        if label_pos == 'right':
            lx = x + w + 3
            ly = y
            # If would go right of image, fall back inside
            if lx + badge_w > img.width:
                lx = x + w - badge_w - 2
                ly = y + 2
        elif label_pos == 'bottom':
            lx = x - 1
            ly = y + h + 2
            # If would go below image, place inside bottom
            if ly + badge_h > img.height:
                ly = y + h - badge_h - 2
        else:
            # Default: above top-left corner
            lx = x - 1
            ly = y - badge_h - 1
            # If would go above image, place inside top-left
            if ly < 0:
                ly = y + 2
                lx = x + 2

        # If would go left of image
        if lx < 0:
            lx = 0

        draw.rectangle([lx, ly, lx + badge_w, ly + badge_h], fill=c)
        draw.text((lx + pad_x, ly + pad_y), label, fill='white', font=font)

    # Composite overlay onto original
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    result = Image.alpha_composite(img, overlay)
    return result.convert('RGB')


def draw_debug_overlay(img, boxes, h_separators=None):
    """Draw debug information: coordinate labels, detected separators."""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Draw detected horizontal separators as thin blue lines
    if h_separators:
        for y in h_separators:
            draw.line([(0, y), (img.width, y)], fill=(0, 120, 255, 80), width=1)
            draw.text((img.width - 40, y - 10), f"y={y}",
                       fill=(0, 120, 255, 160), font=font_small)

    # Draw coordinate labels for each box
    for box in boxes:
        x, y, w, h = box['rect']
        label = str(box['label'])

        # Coordinate text below the box
        coord = f"[{label}] ({x},{y},{w},{h})"
        text_y = y + h + 3
        if text_y + 12 > img.height:
            text_y = y + 2  # inside if no room below
        draw.text((x + 2, text_y), coord,
                   fill=(255, 255, 0, 220), font=font_small)

        # Show delta if available
        delta = box.get('_delta')
        if delta and any(d != 0 for d in delta):
            dx, dy, dw, dh = delta
            delta_text = f"d({dx:+d},{dy:+d},{dw:+d},{dh:+d})"
            draw.text((x + 2, text_y + 12), delta_text,
                       fill=(0, 255, 100, 200), font=font_small)

    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    return Image.alpha_composite(img, overlay).convert('RGB')


# ============================================================
# IMAGE DEFINITIONS
# Each box: {'rect': (x, y, width, height), 'label': str}
# Coordinates measured from pixel analysis of original screenshots
# ============================================================

IMAGES = {
    # --------------------------------------------------------
    # 1. Main Window (765x365) - redesigned 2026-02-11
    # window_rect: 메인 윈도우만 정확히 크롭 (노드 크기에 딱맞게)
    # --------------------------------------------------------
    '01-main-window': {
        'src': '스크린샷 2026-02-05 180630.png',
        'window_rect': (0, 0, 765, 365),
        'boxes': [
            {'rect': (0,   0,   765, 32),  'label': 'M-01'},  # [M-01] Title Bar
            {'rect': (10,  38,  572, 316), 'label': 'M-02'},  # [M-02] Preview Panel
            # CPU/GPU/Error/Lock → 개별 요소로 세분화
            {'rect': (618, 38,  28,  36),  'label': 'M-03'},  # [M-03] CPU Indicator
            {'rect': (648, 38,  28,  36),  'label': 'M-04'},  # [M-04] GPU Indicator
            {'rect': (600, 84,  18,  18),  'label': 'M-05'},  # [M-05] RFID Status LED (빨간 점)
            {'rect': (686, 38,  34,  36),  'label': 'M-06'},  # [M-06] RFID Connection Icon (빨간 금지=미연결 경고)
            {'rect': (722, 38,  34,  36),  'label': 'M-07'},   # [M-07] Lock Toggle (빨간 자물쇠)
            # Secure Delay + Preview ☑ 세분화 (is_drop 유지)
            {'rect': (630, 82,  118, 22),  'label': 'M-08', 'is_drop': True},   # [M-08] Secure Delay ☐ (EBS MVP 범위 외)
            {'rect': (630, 106, 118, 22),  'label': 'M-09'},  # [M-09] Preview Toggle ☑
            # (y=136-152 is empty separator space - no box)
            # Reset Hand 행 → 버튼 + Settings 세분화
            {'rect': (600, 156, 98,  30),  'label': 'M-11'},  # [M-11] Reset Hand 버튼
            {'rect': (702, 156, 46,  30),  'label': 'M-12'},  # [M-12] Settings (톱니바퀴+자물쇠)
            {'rect': (594, 190, 154, 28),  'label': 'M-13'},  # [M-13] Register Deck
            {'rect': (594, 222, 154, 28),  'label': 'M-14'},  # [M-14] Launch AT (Action Tracker)
            {'rect': (594, 254, 154, 28),  'label': 'DROP-Studio',    'is_drop': True},   # Studio (EBS MVP 범위 외)
            {'rect': (594, 286, 154, 28),  'label': 'DROP-SplitRec',  'is_drop': True},   # Split Recording (SV-030 Drop 확정)
            {'rect': (594, 318, 154, 34),  'label': 'DROP-TagPlayer', 'is_drop': True},   # Tag Player (EBS MVP 범위 외)
        ],
    },

    # --------------------------------------------------------
    # 2. Sources Tab (765x730) - 재작업 2026-02-24
    # 오류 수정: 12박스→18박스, 탭바 너비 보정, no_snap 정비
    # 기능 매핑: SV-001~SV-018 (ebs-console-feature-triage.md)
    # Defer v2.0: SV-002 Auto Camera, SV-003 ATEM, SV-004 Board Sync
    # --------------------------------------------------------
    '02-sources-tab': {
        'src': '스크린샷 2026-02-05 180637.png',
        'boxes': [
            # Tab Bar (full width fix: 381→745, Sources|Outputs|GFX1|GFX2|GFX3|Commentary|System)
            {'rect': (9,   363, 745, 16), 'label': '1',  'no_snap': True},  # [S-00] Tab Bar

            # Device Table [S-01]
            {'rect': (9,   379, 556, 86), 'label': '2'},                    # [S-01] Device Table (header + 2 rows)

            # Right Panel - Camera Controls (x=565, w=187)
            {'rect': (565, 385, 187, 26), 'label': '3',  'no_snap': True},  # [S-05] Board Cam Hide GFX ☑
            {'rect': (565, 411, 187, 27), 'label': '4',  'no_snap': True},  # [S-06] Auto Camera Control ☑ [Defer v2.0]
            {'rect': (565, 438, 187, 20), 'label': '5',  'no_snap': True},  # Camera Mode section label
            {'rect': (565, 458, 187, 16), 'label': '6',  'no_snap': True},  # [S-07] Mode: Static ▼
            {'rect': (565, 474, 187, 16), 'label': '7',  'no_snap': True},  # [S-08] Heads Up Split Screen ☑
            {'rect': (565, 490, 187, 15), 'label': '8',  'no_snap': True},  # [S-09] Follow Players ☐
            {'rect': (565, 505, 187, 16), 'label': '9',  'no_snap': True},  # [S-10] Follow Board ☐

            # Right Panel - Linger / Post Bet / Hand
            {'rect': (565, 521, 187, 21), 'label': '10', 'no_snap': True},  # Linger on Board [3]↑↓ S
            {'rect': (565, 542, 187, 21), 'label': '11', 'no_snap': True},  # Post Bet [Default] ▼
            {'rect': (565, 563, 187, 21), 'label': '12', 'no_snap': True},  # Hand [Default] ▼

            # Bottom Row 1 - Chroma Key / Add Camera
            {'rect': (9,   584, 285, 44), 'label': '13'},                   # [S-11/S-12] Background key colour + Chroma Key ☑
            {'rect': (431, 592, 129, 21), 'label': '14'},                   # [S-02] Add Network Camera btn

            # Bottom Row 2 - Audio / Switcher / Sync / Player View
            {'rect': (9,   619, 220, 100), 'label': '15'},                  # [S-17/S-18] Audio Input + Sync + Level
            {'rect': (235, 619, 235, 90),  'label': '16'},                  # [S-13/S-14] External Switcher + ATEM [Defer v2.0]
            {'rect': (477, 619, 88,  90),  'label': '17'},                  # [S-15/S-16] Board Sync + Crossfade [Defer v2.0]
            {'rect': (572, 619, 172, 90),  'label': '18'},                  # Player ▼ + View ▼
        ],
    },

    # --------------------------------------------------------
    # 3. Outputs Tab (765x730) - calibrated 2026-02-10
    # --------------------------------------------------------
    '03-outputs-tab': {
        'src': '스크린샷 2026-02-05 180645.png',
        'boxes': [
            {'rect': (30,  397, 235, 20),  'label': '1'},   # Video Size
            {'rect': (272, 397, 146, 20),  'label': '2',  'is_drop': True},   # 9x16 Vertical [DROP SV-010]
            {'rect': (30,  423, 210, 21),  'label': '3'},   # Frame Rate
            {'rect': (56,  465, 209, 110), 'label': '4'},   # Live column
            {'rect': (271, 465, 142, 110), 'label': '5'},   # Delay column
            {'rect': (33,  601, 232, 20),  'label': '6'},   # Virtual Camera
            {'rect': (17,  677, 460, 32),  'label': '7'},   # Recording Mode
            {'rect': (540, 397, 200, 20),  'label': '8'},   # Secure Delay
            {'rect': (488, 423, 222, 21),  'label': '9'},   # Dynamic Delay
            {'rect': (540, 449, 200, 21),  'label': '10'},  # Auto Stream
            {'rect': (540, 476, 200, 15),  'label': '11'},  # Show Countdown
            {'rect': (488, 500, 252, 131), 'label': '12'},  # Countdown Video + BG
            {'rect': (488, 635, 252, 74),  'label': '13', 'is_drop': True},  # Twitch / ChatBot [DROP SV-011]
        ],
    },

    # --------------------------------------------------------
    # 4. GFX 1 Tab (765x730) - Detailed control-level scan 2026-02-12
    # GroupBox borders (100,100,100): y=385,419,481,488,507,527,709 / x=16,376,383,744
    # Left panel dropdowns (210,210,210 top): y=392,419,445,473,499,525,551,578,604
    # Spinners (171,173,179): x=463 y=536-555/562-581/588-607, x=659 y=681-700
    # Checkboxes: unchecked y=547-559, blue(0,95,184) y=569-581/591-603
    # Gear buttons (208,208,208): x=716-733 y=613-630/635-652/657-674
    # Skin buttons: x=545-626 / x=634-733, face at y=392-413
    # --------------------------------------------------------
    '04-gfx1-tab': {
        'src': '스크린샷 2026-02-05 180649.png',
        'boxes': [
            # Tab Bar
            {'rect': (9,   363, 745, 16),  'label': '1'},   # Tab Bar (full width: Sources|Outputs|GFX1|GFX2|GFX3|Commentary|System)

            # Left Panel - 11 individual control rows (x=16-376)
            {'rect': (16,  385, 360, 31),  'label': '2'},   # Board Position [Right]
            {'rect': (16,  416, 360, 27),  'label': '3'},   # Player Layout [Vert/Bot/Spill]
            {'rect': (16,  443, 360, 28),  'label': '4'},   # Reveal Players [Action On]
            {'rect': (16,  471, 360, 27),  'label': '5'},   # How to show a Fold [Immediate|1.5|S]
            {'rect': (16,  498, 360, 26),  'label': '6'},   # Reveal Cards [Immediate]
            {'rect': (16,  524, 360, 26),  'label': '7'},   # Leaderboard Position [Centre]
            {'rect': (16,  550, 360, 26),  'label': '8'},   # Transition In Animation [Pop|0.5|S]
            {'rect': (16,  576, 360, 26),  'label': '9'},   # Transition Out Animation [Slide|0.4|S]
            {'rect': (16,  602, 360, 26),  'label': '10'},  # Heads Up Layout L/R [Only in split...]
            {'rect': (16,  628, 360, 26),  'label': '11'},  # Heads Up Camera [Camera behind dealer]
            {'rect': (16,  654, 360, 26),  'label': '12'},  # Heads Up Custom Y pos [☐|0.50|%]

            # Skin Area - 3 individual elements (y=385-419)
            {'rect': (383, 385, 161, 34),  'label': '13'},  # Skin Info Label ("Titanium, 1.41 GB")
            {'rect': (545, 385, 82,  34),  'label': '14'},  # [Skin Editor] button
            {'rect': (634, 385, 100, 34),  'label': '15'},  # [Media Folder] button

            # Sponsor Logo Columns (y=419-481, 3 columns)
            {'rect': (393, 419, 93,  62),  'label': '16'},  # Sponsor Logo Col 1
            {'rect': (493, 419, 93,  62),  'label': '17'},  # Sponsor Logo Col 2
            {'rect': (593, 419, 93,  62),  'label': '18'},  # Sponsor Logo Col 3

            # Vanity (y=488-507)
            {'rect': (393, 488, 351, 19),  'label': '19'},  # Vanity [TABLE 2] + Replace checkbox

            # Bottom Section - Margin spinners (left, x=383-533)
            {'rect': (383, 534, 150, 24),  'label': '20'},  # X Margin [0.04] %
            {'rect': (383, 560, 150, 24),  'label': '21'},  # Top Margin [0.05] %
            {'rect': (383, 586, 150, 24),  'label': '22'},  # Bot Margin [0.04] %

            # Bottom Section - Checkbox settings (right, x=535-744)
            {'rect': (535, 534, 209, 24),  'label': '23'},  # Show Heads Up History ☐
            {'rect': (535, 560, 209, 24),  'label': '24'},  # Indent Action Player ☑
            {'rect': (535, 586, 209, 24),  'label': '25'},  # Bounce Action Player ☑

            # Bottom Section - Gear settings (full width, each with ☐ + ⚙)
            {'rect': (383, 611, 361, 22),  'label': '26'},  # Show leaderboard after each hand
            {'rect': (383, 633, 361, 22),  'label': '27'},  # Show PIP Capture after each hand
            {'rect': (383, 655, 361, 22),  'label': '28'},  # Show player stats in ticker

            # Action Clock (bottom)
            {'rect': (383, 678, 361, 24),  'label': '29'},  # Show Action Clock at [10] S
        ],
    },

    # --------------------------------------------------------
    # 5. GFX 2 Tab (765x730) - redesigned 2026-02-23
    # GroupBox borders: H y=385,709  V x=16,330,337,732
    # Left panel: x=16-330, Right panel: x=337-732
    # OCR row anchors (detect_ui_elements --target 05):
    #   L-row text y: 401,423,445,467,489,512 / 562,584,606,628
    #   R-row text y: 401,423,445,467,482~491,515~517,540,565,581~593,615
    # --------------------------------------------------------
    '05-gfx2-tab': {
        'src': '스크린샷 2026-02-05 180652.png',
        'boxes': [
            # Tab Bar
            {'rect': (9,   363, 745, 17),  'label': '1'},   # Tab Bar (full width: Sources|Outputs|GFX1|GFX2|GFX3|Commentary|System)
            # Left Panel - Leaderboard Options (6 rows, x=16-330)
            {'rect': (16,  393, 314, 22),  'label': '2',  'no_snap': True},  # Show knockout rank in Leaderboard ☐
            {'rect': (16,  415, 314, 22),  'label': '3',  'no_snap': True},  # Show Chipcount % in Leaderboard ☑
            {'rect': (16,  437, 314, 22),  'label': '4'},                    # Show eliminated players in Leaderboard stats ☑
            {'rect': (16,  459, 314, 22),  'label': '5',  'no_snap': True},  # Show Chipcount with Cumulative Winnings ☐
            {'rect': (16,  481, 314, 22),  'label': '6',  'no_snap': True},  # Hide leaderboard when hand starts ☑
            {'rect': (16,  503, 314, 28),  'label': '7'},                    # Max BB multiple to show in Leaderboard [200]
            # Left Panel - Game Rules (4 rows) — all no_snap
            {'rect': (16,  554, 314, 22),  'label': '8',  'no_snap': True},  # Move button after Bomb Pot ☐
            {'rect': (16,  576, 314, 22),  'label': '9',  'no_snap': True},  # Limit Raises to Effective Stack size ☐
            {'rect': (16,  598, 314, 22),  'label': '10', 'no_snap': True},  # Straddle not on the button or UTG is sleeper ☐
            {'rect': (16,  620, 314, 22),  'label': '11', 'no_snap': True},  # Sleeper straddle gets final action ☐
            # Right Panel (10 rows, x=337-732)
            {'rect': (337, 393, 395, 22),  'label': '12', 'no_snap': True},  # Add seat # to player name ☐
            {'rect': (337, 415, 395, 22),  'label': '13'},                   # Show as eliminated when player loses stack ☑
            {'rect': (337, 437, 395, 22),  'label': '14', 'no_snap': True},  # Allow Rabbit Hunting ☐
            {'rect': (337, 459, 395, 24),  'label': '15'},                   # Unknown cards blink in Secure Mode ☑
            {'rect': (337, 483, 395, 25),  'label': '16', 'no_snap': True},  # Hilite Nit game players when [At Risk] ▼
            {'rect': (337, 508, 395, 24),  'label': '17', 'no_snap': True},  # Clear previous action & show 'x to call' ☑
            {'rect': (337, 532, 395, 24),  'label': '18'},                   # Order players from the first [To the left] ▼
            {'rect': (337, 556, 395, 26),  'label': '19'},                   # Show hand equities [After 1st betting round] ▼
            {'rect': (337, 582, 395, 26),  'label': '20', 'no_snap': True},  # Hilite winning hand [Immediately] ▼
            {'rect': (337, 608, 395, 22),  'label': '21', 'no_snap': True},  # When showing equity+outs, ignore split pots ☐
        ],
    },

    # --------------------------------------------------------
    # 6. GFX3 Tab (765x730) - pixel-scanned 2026-02-12
    # GroupBox borders: H y=385,709  V x=16,281,288,677
    # Left panel: x=16-281, Right panel: x=288-677
    # --------------------------------------------------------
    '06-gfx3-tab': {
        'src': '스크린샷 2026-02-05 180655.png',
        'boxes': [
            # Tab Bar
            {'rect': (9,   363, 745, 16),  'label': '1'},   # Tab Bar (full width: Sources|Outputs|GFX1|GFX2|GFX3|Commentary|System)
            # Left Panel - Outs section (x=16-281)
            {'rect': (16,  392, 265, 26),  'label': '2'},   # Show Outs [Heads Up or All In Showdown] ▼
            {'rect': (16,  418, 265, 26),  'label': '3'},   # Outs Position [Left] ▼
            {'rect': (16,  444, 265, 22),  'label': '4'},   # True Outs ☑
            # Left Panel - Score Strip section
            {'rect': (16,  473, 265, 26),  'label': '5'},   # Score Strip [Off] ▼
            {'rect': (16,  499, 265, 26),  'label': '6'},   # Order Strip by [Chip Count] ▼
            {'rect': (16,  525, 265, 20),  'label': '7'},   # Show eliminated players in Strip ☐
            # Left Panel - Blinds section
            {'rect': (16,  556, 265, 26),  'label': '8'},   # Show Blinds [Never] ▼
            {'rect': (16,  582, 265, 20),  'label': '9'},   # Show hand # with blinds ☑
            # Left Panel - Currency section
            {'rect': (16,  636, 265, 24),  'label': '10'},  # Currency Symbol [W] ☐
            {'rect': (16,  660, 265, 22),  'label': '11'},  # Trailing Currency Symbol ☐
            {'rect': (16,  682, 265, 20),  'label': '12'},  # Divide all amounts by 100 ☐
            # Right Panel - Chipcount Precision (x=288-677, 8 dropdown rows)
            {'rect': (288, 392, 389, 26),  'label': '13'},  # Leaderboard [Exact Amount] ▼
            {'rect': (288, 418, 389, 26),  'label': '14'},  # Player Stack [Smart Amount ('k' & 'M')] ▼
            {'rect': (288, 444, 389, 26),  'label': '15'},  # Player Action [Smart Amount ('k' & 'M')] ▼
            {'rect': (288, 470, 389, 26),  'label': '16'},  # Blinds [Smart Amount ('k' & 'M')] ▼
            {'rect': (288, 496, 389, 26),  'label': '17'},  # Pot [Smart Amount ('k' & 'M')] ▼
            {'rect': (288, 522, 389, 26),  'label': '18'},  # Twitch Bot [Exact Amount] ▼
            {'rect': (288, 548, 389, 26),  'label': '19'},  # Ticker [Exact Amount] ▼
            {'rect': (288, 574, 389, 26),  'label': '20'},  # Strip [Exact Amount] ▼
            # Right Panel - How to display amounts (3 dropdown rows)
            {'rect': (288, 622, 389, 26),  'label': '21'},  # Chipcounts [Amount] ▼
            {'rect': (288, 648, 389, 26),  'label': '22'},  # Pot [Amount] ▼
            {'rect': (288, 674, 389, 26),  'label': '23'},  # Bets [Amount] ▼
        ],
    },

    # --------------------------------------------------------
    # 7. Commentary Tab (765x730) - calibrated 2026-02-10
    # --------------------------------------------------------
    '07-commentary-tab': {
        'src': '스크린샷 2026-02-05 180659.png',
        'boxes': [
            # Tab Bar
            {'rect': (9,   363, 745, 16),  'label': '1'},   # Tab Bar (full width: Sources|Outputs|GFX1|GFX2|GFX3|Commentary|System)
            # Commentary Panel (x=16-533, y=385-572)
            {'rect': (16,  394, 517, 26),  'label': '2',  'is_drop': True},   # Commentary Mode [DROP SV-021]
            {'rect': (16,  422, 517, 24),  'label': '3',  'is_drop': True},   # Password field [DROP SV-021]
            {'rect': (16,  472, 517, 22),  'label': '4',  'is_drop': True},   # Statistics only [DROP SV-021]
            {'rect': (16,  494, 517, 22),  'label': '5',  'is_drop': True},   # Allow commentator to control leaderboard [DROP SV-021]
            {'rect': (16,  516, 326, 22),  'label': '6',  'is_drop': True},   # Commentator camera as well as audio [DROP SV-021]
            {'rect': (345, 516, 168, 22),  'label': '7',  'is_drop': True},   # [Configure Picture In Picture] btn [DROP SV-021]
            {'rect': (16,  540, 517, 22),  'label': '8',  'is_drop': True},   # Allow commentator camera to go full screen [DROP SV-021]
        ],
    },

    # --------------------------------------------------------
    # 8. System Tab (765x730) - recalibrated 2026-02-12 (28 individual controls)
    # --------------------------------------------------------
    '08-system-tab': {
        'src': '스크린샷 2026-02-05 180624.png',
        'boxes': [
            # Tab Bar
            {'rect': (9,   363, 381, 16),  'label': '1'},   # Tab Bar (Sources|...|Commentary|System)
            # --- Table GroupBox (x=16-237, y=385-534) ---
            {'rect': (27,  421, 199, 20),  'label': '2'},   # Name [GGP] + [Update]
            {'rect': (27,  448, 199, 20),  'label': '3'},   # Pwd [CCC] + [Update]
            {'rect': (27,  499, 41,  20),  'label': '4'},   # [Reset] button
            {'rect': (80,  499, 63,  20),  'label': '5'},   # [Calibrate] button
            # --- License GroupBox (x=244-505, y=385-534) ---
            {'rect': (335, 393, 150, 20),  'label': '6'},   # Serial # 674
            {'rect': (290, 418, 180, 24),  'label': '7'},   # [Check for Updates]
            {'rect': (255, 450, 135, 42),  'label': '8'},   # Updates & support + [Evaluation mode]
            {'rect': (395, 450, 100, 42),  'label': '9'},   # PRO license + [Evaluation mode]
            # --- Right Panel (x=512-751, y=385-717) ---
            {'rect': (555, 395, 190, 20),  'label': '10'},  # [Open Table Diagnostics]
            {'rect': (555, 420, 190, 140), 'label': '11'},  # System info (CPU/GPU/OS/Encoder)
            {'rect': (555, 563, 190, 19),  'label': '12'},  # [View System Log]
            {'rect': (612, 607, 124, 19),  'label': '13'},  # [Secure Delay Folder]
            {'rect': (612, 637, 124, 19),  'label': '14'},  # [Export Folder]
            {'rect': (555, 678, 190, 17),  'label': '15'},  # Stream Deck [Disabled] ▼
            # --- Checkboxes Left Column ---
            {'rect': (16,  543, 98,  20),  'label': '16'},  # MultiGFX ☐
            {'rect': (16,  565, 100, 20),  'label': '17'},  # Sync Stream ☐
            {'rect': (16,  587, 100, 20),  'label': '18'},  # Sync Skin ☐
            {'rect': (16,  609, 100, 20),  'label': '19'},  # No Cards ☐
            {'rect': (16,  653, 148, 20),  'label': '20'},  # Disable GPU Encode ☐
            {'rect': (16,  675, 148, 20),  'label': '21'},  # Ignore Name Tags ☑
            # --- Checkboxes Right Column ---
            {'rect': (118, 543, 387, 20),  'label': '22'},  # UPCARD antennas read hole cards... ☐
            {'rect': (160, 565, 345, 20),  'label': '23'},  # Disable muck antenna when in... ☐
            {'rect': (160, 587, 345, 20),  'label': '24'},  # Disable Community Card antenna... ☐
            {'rect': (160, 609, 345, 20),  'label': '25'},  # Auto Start PokerGFX Server... ☐
            {'rect': (285, 631, 220, 20),  'label': '26'},  # Allow Action Tracker access ☑
            {'rect': (210, 653, 295, 20),  'label': '27'},  # Action Tracker Predictive Bet Input ☐
            {'rect': (300, 675, 205, 20),  'label': '28'},  # Action Tracker Kiosk ☐
        ],
    },

    # --------------------------------------------------------
    # 9. Skin Editor (883x461) - no_snap fixes 2026-02-23 (37 individual controls)
    # --------------------------------------------------------
    '09-skin-editor': {
        'src': '스크린샷 2026-02-05 180715.png',
        'boxes': [
            # --- Header ---
            {'rect': (5,   39,  462, 20),  'label': '1'},   # Name [Titanium]
            {'rect': (5,   62,  462, 17),  'label': '2'},   # Details [Modern, layered skin...]
            {'rect': (480, 39,  385, 18),  'label': '3',  'no_snap': True},   # Remove Partial Transparency... ☐
            {'rect': (620, 62,  248, 17),  'label': '4'},   # Designed for 4K (3840 x 2160) ☐
            # --- Adjustments GroupBox (y=86-164) ---
            {'rect': (20,  106, 140, 38),  'label': '5'},   # Adjust Size slider
            # --- Elements GroupBox (y=164-298) ---
            {'rect': (300, 180, 130, 21),  'label': '6'},   # [Strip]
            {'rect': (27,  208, 126, 21),  'label': '7'},   # [Board]
            {'rect': (164, 208, 126, 21),  'label': '8'},   # [Blinds]
            {'rect': (301, 208, 126, 21),  'label': '9'},   # [Outs]
            {'rect': (27,  236, 126, 21),  'label': '10'},  # [Hand History]
            {'rect': (164, 236, 126, 21),  'label': '11'},  # [Action Clock]
            {'rect': (301, 236, 126, 21),  'label': '12'},  # [Leaderboard]
            {'rect': (27,  264, 126, 21),  'label': '13'},  # [Split Screen Divider]
            {'rect': (164, 264, 126, 21),  'label': '14'},  # [Ticker]
            {'rect': (301, 264, 126, 21),  'label': '15'},  # [Field]
            # --- Text GroupBox (y=298-390) ---
            {'rect': (136, 311, 128, 18),  'label': '16'},  # Text All Caps ☑
            {'rect': (278, 311, 150, 18),  'label': '17'},  # Text Reveal Speed slider
            {'rect': (13,  340, 285, 22),  'label': '18'},  # Font 1 [Gotham] [...]
            {'rect': (13,  366, 285, 22),  'label': '19'},  # Font 2 [Gotham] [...]
            {'rect': (310, 366, 120, 22),  'label': '20'},  # [Language]
            # --- Cards GroupBox (x=443-866, y=99-164) ---
            {'rect': (456, 100, 225, 26),  'label': '21'},  # Card display (card images)
            {'rect': (685, 127, 173, 21),  'label': '22'},  # [Add] [Replace] [Delete]
            {'rect': (685, 155, 173, 21),  'label': '23'},  # [Import Card Back]
            # --- Flags GroupBox (x=443-866, y=186-252) ---
            {'rect': (545, 197, 300, 18),  'label': '24'},  # Country flag does not force... ☑
            {'rect': (449, 219, 67,  21),  'label': '25'},  # [Edit Flags]
            {'rect': (545, 219, 316, 22),  'label': '26'},  # Hide flag after [0.0] S (0=Do not hide)
            # --- Player GroupBox (x=443-866, y=259-390) ---
            {'rect': (449, 303, 172, 22),  'label': '27'},  # Variant [HOLDEM (2 Cards)] ▼
            {'rect': (683, 303, 173, 22),  'label': '28'},  # Player Set [2 Card Games] ▼
            {'rect': (490, 330, 140, 20),  'label': '29'},  # Override Card Set ☐
            {'rect': (683, 328, 173, 21),  'label': '30'},  # [Edit] [New] [Delete]
            {'rect': (650, 358, 210, 18),  'label': '31'},  # Crop player photo to circle ☐
            # --- Bottom Buttons (y=400-449) ---
            {'rect': (12,  400, 131, 49),  'label': '32'},  # [IMPORT]
            {'rect': (149, 400, 131, 49),  'label': '33'},  # [EXPORT]
            {'rect': (286, 400, 131, 49),  'label': '34'},  # [SKIN DOWNLOAD CENTRE]
            {'rect': (423, 400, 131, 49),  'label': '35'},  # [RESET TO DEFAULT]
            {'rect': (560, 400, 131, 49),  'label': '36'},  # [DISCARD]
            {'rect': (697, 400, 131, 49),  'label': '37'},  # [USE]
        ],
    },

    # --------------------------------------------------------
    # 10. Graphic Editor - Board (644x582) - no_snap fixes 2026-02-23
    # --------------------------------------------------------
    '10-graphic-editor-board': {
        'src': '스크린샷 2026-02-05 180720.png',
        'boxes': [
            # --- Top Bar ---
            {'rect': (290, 30,  125, 18),  'label': '1'},   # Layout Size [296 X 197]
            # --- Import / Mode Row (y=68-102) ---
            {'rect': (30,  76,  88,  22),  'label': '2'},   # [Import Image] button
            {'rect': (125, 76,  158, 22),  'label': '3'},   # AT Mode (Flop Game) ▼
            # --- Right Panel: Element ---
            {'rect': (497, 48,  115, 22),  'label': '4',  'no_snap': True},   # Element [Card 1 ▼]
            # --- Right Panel: Position/Anchor ---
            {'rect': (468, 86,  65,  20),  'label': '5',  'no_snap': True},   # Left [288 ⬆⬇]
            {'rect': (540, 86,  72,  20),  'label': '6'},   # Anchor [Right ▼]
            {'rect': (468, 110, 65,  20),  'label': '7'},   # Top [0 ⬆⬇]
            {'rect': (540, 110, 72,  20),  'label': '8'},   # Anchor [Top ▼]
            {'rect': (468, 134, 65,  20),  'label': '9'},   # Width [56 ⬆⬇]
            {'rect': (560, 134, 52,  20),  'label': '10'},  # Z [1 ⬆⬇]
            {'rect': (468, 158, 65,  20),  'label': '11'},  # Height [80 ⬆⬇]
            {'rect': (560, 158, 52,  20),  'label': '12'},  # < [0 ⬆⬇]
            # --- Animation (y=102-198) ---
            {'rect': (36,  138, 72,  22),  'label': '13'},  # [AnimIn] button
            {'rect': (116, 138, 22,  22),  'label': '14'},  # [X] dismiss AnimIn
            {'rect': (146, 141, 75,  16),  'label': '15'},  # AnimIn slider (blue)
            {'rect': (36,  166, 72,  22),  'label': '16'},  # [AnimOut] button
            {'rect': (116, 166, 22,  22),  'label': '17'},  # [X] dismiss AnimOut
            {'rect': (146, 169, 75,  16),  'label': '18'},  # AnimOut slider (blue)
            {'rect': (270, 138, 125, 22),  'label': '19'},  # Transition In [-- Default -- ▼]
            {'rect': (270, 166, 125, 22),  'label': '20'},  # Transition Out [-- Default -- ▼]
            # --- Text Visible (y=198-353) ---
            {'rect': (20,  207, 120, 16),  'label': '21',  'no_snap': True},  # ☐ Text Visible
            {'rect': (141, 237, 152, 22),  'label': '22'},  # Font [Font 1 - Gotham ▼]
            {'rect': (300, 232, 36,  22),  'label': '23',  'no_snap': True},  # Colour swatch
            {'rect': (370, 232, 36,  22),  'label': '24',  'no_snap': True},  # Hilite Col swatch
            {'rect': (141, 261, 152, 22),  'label': '25'},  # Alignment [Left ▼]
            {'rect': (300, 264, 36,  22),  'label': '26'},  # Colour swatch (Alignment)
            {'rect': (80,  295, 55,  16),  'label': '27'},  # ☐ Drop Shadow
            {'rect': (141, 291, 152, 22),  'label': '28'},  # [North ▼] dropdown
            {'rect': (318, 294, 36,  22),  'label': '29',  'no_snap': True},  # Colour swatch (Shadow)
            {'rect': (100, 321, 90,  20),  'label': '30'},  # Rounded Corners [0 ⬆⬇]
            {'rect': (262, 321, 70,  20),  'label': '31'},  # Margins X [0 ⬆⬇]
            {'rect': (350, 321, 55,  20),  'label': '32'},  # Y [0 ⬆⬇]
            # --- Right Side Controls ---
            {'rect': (566, 208, 64,  30),  'label': '33'},  # [Adjust Colours] button
            {'rect': (445, 242, 112, 58),  'label': '34'},  # Background Image area
            {'rect': (527, 310, 20,  18),  'label': '35'},  # [X] dismiss background
            {'rect': (440, 328, 120, 16),  'label': '36',  'no_snap': True},  # ☐ Triggered by Language text
            {'rect': (566, 296, 64,  24),  'label': '37'},  # [OK] button
            {'rect': (566, 330, 64,  24),  'label': '38'},  # [Cancel] button
            # --- Preview ---
            {'rect': (16,  365, 340, 200), 'label': '39'},  # Live Preview
        ],
    },

    # --------------------------------------------------------
    # 11. Graphic Editor - Player (644x505) - no_snap fixes 2026-02-23
    # Red boxes for editor controls, Green boxes for preview overlay elements
    # Editor controls share identical GroupBox positions with Image 10
    # --------------------------------------------------------
    '11-graphic-editor-player': {
        'src': '스크린샷 2026-02-05 180728.png',
        'boxes': [
            # --- Top Bar (Player Set row, y=39-68) ---
            {'rect': (91,  42,  198, 18),  'label': '1'},   # Player Set [2 Card Games ▼]
            {'rect': (310, 42,  80,  18),  'label': '2'},   # Layout Size [465 X 120]
            # --- Import / Mode Row (y=68-102) ---
            {'rect': (30,  76,  88,  22),  'label': '3'},   # [Import Image] button
            {'rect': (125, 76,  158, 22),  'label': '4'},   # AT Mode with photo ▼
            # --- Right Panel: Element ---
            {'rect': (497, 48,  115, 22),  'label': '5',  'no_snap': True},   # Element [Card 1 ▼]
            # --- Right Panel: Position/Anchor ---
            {'rect': (468, 86,  65,  20),  'label': '6',  'no_snap': True},   # Left [372 ⬆⬇]
            {'rect': (540, 86,  72,  20),  'label': '7'},   # Anchor [Right ▼]
            {'rect': (468, 110, 65,  20),  'label': '8'},   # Top [5 ⬆⬇]
            {'rect': (540, 110, 72,  20),  'label': '9'},   # Anchor [Top ▼]
            {'rect': (468, 134, 65,  20),  'label': '10'},  # Width [44 ⬆⬇]
            {'rect': (560, 134, 52,  20),  'label': '11'},  # Z [1 ⬆⬇]
            {'rect': (468, 158, 65,  20),  'label': '12'},  # Height [64 ⬆⬇]
            {'rect': (560, 158, 52,  20),  'label': '13'},  # < [0 ⬆⬇]
            # --- Animation (y=102-198) ---
            {'rect': (36,  138, 72,  22),  'label': '14'},  # [AnimIn] button
            {'rect': (116, 138, 22,  22),  'label': '15'},  # [X] dismiss AnimIn
            {'rect': (146, 141, 75,  16),  'label': '16'},  # AnimIn slider (blue)
            {'rect': (36,  166, 72,  22),  'label': '17'},  # [AnimOut] button
            {'rect': (116, 166, 22,  22),  'label': '18'},  # [X] dismiss AnimOut
            {'rect': (146, 169, 75,  16),  'label': '19'},  # AnimOut slider (blue)
            {'rect': (270, 138, 125, 22),  'label': '20'},  # Transition In [-- Default -- ▼]
            {'rect': (270, 166, 125, 22),  'label': '21'},  # Transition Out [-- Default -- ▼]
            # --- Text Visible (y=198-353) ---
            {'rect': (20,  207, 120, 16),  'label': '22',  'no_snap': True},  # ☐ Text Visible
            {'rect': (141, 237, 152, 22),  'label': '23'},  # Font [Font 1 - Gotham ▼]
            {'rect': (300, 232, 36,  22),  'label': '24',  'no_snap': True},  # Colour swatch
            {'rect': (370, 232, 36,  22),  'label': '25',  'no_snap': True},  # Hilite Col swatch
            {'rect': (141, 261, 152, 22),  'label': '26'},  # Alignment [Left ▼]
            {'rect': (300, 264, 36,  22),  'label': '27'},  # Colour swatch (Alignment)
            {'rect': (80,  295, 55,  16),  'label': '28'},  # ☐ Drop Shadow
            {'rect': (141, 291, 152, 22),  'label': '29'},  # [North ▼] dropdown
            {'rect': (318, 294, 36,  22),  'label': '30',  'no_snap': True},  # Colour swatch (Shadow)
            {'rect': (100, 321, 90,  20),  'label': '31'},  # Rounded Corners [0 ⬆⬇]
            {'rect': (262, 321, 70,  20),  'label': '32'},  # Margins X [0 ⬆⬇]
            {'rect': (350, 321, 55,  20),  'label': '33'},  # Y [0 ⬆⬇]
            # --- Right Side Controls ---
            {'rect': (566, 208, 64,  30),  'label': '34'},  # [Adjust Colours] button
            {'rect': (445, 242, 112, 58),  'label': '35'},  # Background Image area
            {'rect': (527, 310, 20,  18),  'label': '36'},  # [X] dismiss background
            {'rect': (440, 328, 120, 16),  'label': '37',  'no_snap': True},  # ☐ Triggered by Language text
            {'rect': (566, 296, 64,  24),  'label': '38'},  # [OK] button
            {'rect': (566, 330, 64,  24),  'label': '39'},  # [Cancel] button
            # --- Preview Area ---
            {'rect': (16,  355, 465, 130), 'label': '40'},  # Live Preview
            # --- Green: Overlay elements in preview ---
            {'rect': (19,  370, 88,  115), 'label': 'A',  'color': GREEN},  # Player Photo
            {'rect': (108, 371, 48,  68),  'label': 'B',  'color': GREEN},  # Hole Cards
            {'rect': (168, 383, 182, 28),  'label': 'C',  'color': GREEN},  # NAME
            {'rect': (385, 399, 36,  14),  'label': 'D',  'color': GREEN},  # Country Flag
            {'rect': (425, 383, 47,  30),  'label': 'E',  'color': GREEN},  # Equity %
            {'rect': (108, 440, 170, 30),  'label': 'F',  'color': GREEN},  # ACTION
            {'rect': (280, 433, 145, 48),  'label': 'G',  'color': GREEN},  # STACK
            {'rect': (428, 435, 52,  45),  'label': 'H',  'color': GREEN},  # POS
        ],
    },
}


# ============================================================
# EBS CONSOLE ANNOTATION
# ============================================================

EBS_INPUT_DIR = "C:/claude/ebs/docs/02-design/mockups/v3"
EBS_OUTPUT_DIR = "C:/claude/ebs/docs/01_PokerGFX_Analysis/02_Annotated_ngd"

# Annotation color for EBS: cyan to distinguish from PokerGFX red
EBS_COLOR = (0, 180, 220)

# EBS Console: single source of truth — ebs-console-main-v4.html
# Each entry: (html_file, tab_name, scope_filter)
# - tab_name: Playwright clicks .tab[data-tab="{tab_name}"] to activate that tab
# - scope_filter: 'common' for main-window (Menu Bar + Preview + Info Bar only)
#                 None for tab views (extracts elements inside active panel)
EBS_HTML_MAP = {
    'ebs-main-window':  ('ebs-console-main-v4.html', None,       'common'),
    'ebs-sources-tab':  ('ebs-console-main-v4.html', 'sources',  None),
    'ebs-outputs-tab':  ('ebs-console-main-v4.html', 'outputs',  None),
    'ebs-gfx-tab':      ('ebs-console-main-v4.html', 'gfx',      None),
    'ebs-display-tab':  ('ebs-console-main-v4.html', 'display',  None),
    'ebs-rules-tab':    ('ebs-console-main-v4.html', 'rules',    None),
    'ebs-system-tab':   ('ebs-console-main-v4.html', 'system',   None),
}


def extract_coords_from_html(html_path, png_path, tab_name=None, scope_filter=None):
    """Extract annotation coordinates from HTML using Playwright.

    Renders the HTML file in headless Chromium, optionally clicks a tab to activate it,
    captures a screenshot of the .app element, and extracts bounding boxes for
    elements with [data-ann] attribute filtered by scope.

    Args:
        html_path: Path to the HTML file
        png_path: Path to save the screenshot
        tab_name: If set, clicks .tab[data-tab="{tab_name}"] before capturing
        scope_filter: 'common' = only data-ann-scope="common" elements
                      None (with tab_name) = elements inside the active panel
                      None (without tab_name) = all elements

    Returns:
        list: boxes compatible with draw_boxes() format
    """
    color_map = {
        'GREEN': GREEN,
        'EBS_COLOR': EBS_COLOR,
    }

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={'width': 1200, 'height': 1600})
        page.goto(f'file:///{html_path.replace(chr(92), "/")}')
        page.wait_for_load_state('networkidle')

        # Click tab to activate if specified
        if tab_name:
            tab_selector = f'.tab[data-tab="{tab_name}"]'
            tab_el = page.locator(tab_selector)
            if tab_el.count() > 0:
                tab_el.first.click()
                # Wait for panel to become visible
                panel_selector = f'#panel-{tab_name}'
                page.wait_for_selector(f'{panel_selector}.active', timeout=3000)
            else:
                print(f"  WARNING: Tab '{tab_name}' not found")

        # Find the .app container
        app_locator = page.locator('.app')
        if app_locator.count() == 0:
            app_locator = page.locator('#app')

        app_box = app_locator.first.bounding_box()
        if not app_box:
            print(f"  ERROR: .app / #app container not found in {html_path}")
            browser.close()
            return []

        app_x, app_y = app_box['x'], app_box['y']

        # Screenshot the .app element
        app_locator.first.screenshot(path=png_path)

        # Extract [data-ann] elements with scope filtering
        elements = page.query_selector_all('[data-ann]')
        boxes = []
        for el in elements:
            ann = el.get_attribute('data-ann')
            fn = el.get_attribute('data-ann-fn') or ann
            color_name = el.get_attribute('data-ann-color') or 'EBS_COLOR'
            label_pos = el.get_attribute('data-ann-pos')
            el_scope = el.get_attribute('data-ann-scope')

            # Scope filtering
            if scope_filter == 'common':
                # Only include elements explicitly marked as common
                if el_scope != 'common':
                    continue
            elif tab_name:
                # For tab views: include elements scoped to this tab
                if el_scope and el_scope != tab_name:
                    continue

            bbox = el.bounding_box()
            if bbox is None:
                print(f"  WARNING: [data-ann=\"{ann}\"] has no bounding box, skipping")
                continue

            x = round(bbox['x'] - app_x)
            y = round(bbox['y'] - app_y)
            w = round(bbox['width'])
            h = round(bbox['height'])

            box = {
                'rect': (x, y, w, h),
                'label': ann,
                'fn': fn,
                'color': color_map.get(color_name, EBS_COLOR),
            }
            if label_pos:
                box['label_pos'] = label_pos

            boxes.append(box)

        browser.close()

    return boxes


# ============================================================
# MAIN
# ============================================================

def process_image(name, data, mode='normal', snap=True, input_dir=None, output_dir=None):
    """Process a single image. mode: 'normal', 'calibrate', 'debug', 'ocr', 'crop'.
    snap: if True, auto-calibrate box positions in normal mode.
    """
    src_dir = input_dir or INPUT_DIR
    dst_dir = output_dir or OUTPUT_DIR
    src_path = os.path.join(src_dir, data['src'])
    if not os.path.exists(src_path):
        print(f"SKIP (not found): {src_path}")
        return None

    img = Image.open(src_path).copy()
    boxes = data['boxes']

    # window_rect: 메인 윈도우만 정확 크롭 (딱맞게, 패딩 없음)
    window_rect = data.get('window_rect')
    if window_rect:
        wx, wy, ww, wh = window_rect
        img = img.crop((wx, wy, wx + ww, wy + wh))
        if wx != 0 or wy != 0:
            boxes = [dict(b, rect=(b['rect'][0] - wx, b['rect'][1] - wy,
                                   b['rect'][2], b['rect'][3])) for b in boxes]

    if mode == 'crop':
        # Use edge-snap calibrated coordinates for accurate cropping
        calibrated = auto_calibrate(img, boxes)
        dst_dir = os.path.join(CROP_DIR, name)
        crop_count = crop_boxes(img, calibrated, dst_dir, name)
        print(f"CROP: {dst_dir} ({crop_count} crops generated)")
        return crop_count

    elif mode == 'calibrate':
        calibrated = auto_calibrate(img, boxes)
        # Print calibration report
        print(f"\n{'='*60}")
        print(f"  {name}  ({img.size[0]}x{img.size[1]})")
        print(f"{'='*60}")
        changed = 0
        for cb in calibrated:
            lbl = cb['label']
            orig = cb.get('_original', cb['rect'])
            curr = cb['rect']
            delta = cb.get('_delta', (0, 0, 0, 0))
            moved = any(d != 0 for d in delta)
            marker = " << MOVED" if moved else ""
            if moved:
                changed += 1
            print(f"  [{lbl:>2}] {str(orig):>22} -> {str(curr):<22}{marker}")
            if moved:
                dx, dy, dw, dh = delta
                print(f"        delta: x{dx:+d} y{dy:+d} w{dw:+d} h{dh:+d}")
        print(f"\n  {changed}/{len(calibrated)} boxes adjusted")

        # Check for empty boxes
        empty_warnings = check_empty_boxes(img, calibrated)
        for w in empty_warnings:
            print(f"  WARN: Box [{w['label']}] ({w['rect']}) "
                  f"variance={w['variance']} avg={w['avg_color']} - may be empty")

        # Generate calibrated overlay
        dst_path = os.path.join(dst_dir, f"{name}.png")
        result = draw_boxes(img, calibrated)
        result.save(dst_path, quality=95)
        print(f"  -> {dst_path}")

        # Save calibrated coordinates to JSON sidecar (Fix #3)
        json_path = os.path.join(dst_dir, f"{name}-calibrated.json")
        json_data = {
            'name': name,
            'src': data['src'],
            'size': list(img.size),
            'boxes': [],
        }
        for cb in calibrated:
            entry = {
                'rect': list(cb['rect']),
                'label': cb['label'],
            }
            if cb.get('color') and cb['color'] != RED:
                entry['color'] = 'GREEN' if cb['color'] == GREEN else 'BLUE'
            if cb.get('_delta') and any(d != 0 for d in cb['_delta']):
                entry['delta'] = list(cb['_delta'])
            entry['original'] = list(cb.get('_original', cb['rect']))
            json_data['boxes'].append(entry)
        json_data['empty_warnings'] = empty_warnings
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        print(f"  -> {json_path}")

        # Print Python dict for copy-paste
        print(f"\n  # Copy-paste replacement:")
        print(f"  'boxes': [")
        for cb in calibrated:
            x, y, w, h = cb['rect']
            lbl = cb['label']
            color = cb.get('color')
            if color and color != RED:
                color_name = 'GREEN' if color == GREEN else 'BLUE'
                print(f"      {{'rect': ({x:<4d} {y:<4d} {w:<4d} {h:<3d}),"
                      f" 'label': '{lbl}', 'color': {color_name}}},")
            else:
                print(f"      {{'rect': ({x:<4d} {y:<4d} {w:<4d} {h:<3d}),"
                      f" 'label': '{lbl}'}},")
        print(f"  ],")

        return calibrated

    elif mode == 'ocr':
        print(f"\n{'='*60}")
        print(f"  {name}  ({img.size[0]}x{img.size[1]})  [OCR mode]")
        print(f"{'='*60}")

        if not TESSERACT_AVAILABLE:
            print("  [OCR] Tesseract/pytesseract not available.")
            print("  [OCR] Falling back to edge-detection only.")
            calibrated = auto_calibrate(img, boxes)
        else:
            # Step 1: OCR-based coordinate refinement
            ocr_boxes = ocr_calibrate(img, boxes)

            # Step 2: Apply additional edge-detection snap on top of OCR results
            print(f"  [OCR] Applying edge-detection snap on OCR-refined boxes...")
            calibrated_raw = auto_calibrate(img, ocr_boxes)

            # Merge metadata: preserve OCR text/count from ocr_boxes into final result
            calibrated = []
            for i, cb in enumerate(calibrated_raw):
                ocr_meta = ocr_boxes[i]
                cb['_ocr_text'] = ocr_meta.get('_ocr_text', '')
                cb['_ocr_count'] = ocr_meta.get('_ocr_count', 0)
                calibrated.append(cb)

        # Print calibration summary
        changed = sum(1 for b in calibrated
                      if b.get('_delta') and any(d != 0 for d in b['_delta']))
        ocr_adjusted = sum(1 for b in calibrated if b.get('_ocr_count', 0) > 0)
        protected = sum(1 for b in calibrated if b.get('_auto_protected'))
        print(f"\n  Summary: {changed}/{len(calibrated)} boxes moved after OCR+edge-snap")
        print(f"  OCR text found in: {ocr_adjusted}/{len(calibrated)} boxes")
        print(f"  Auto-protected (delta guard): {protected}/{len(calibrated)} boxes")

        # Check empty boxes
        empty_warnings = check_empty_boxes(img, calibrated)
        for w in empty_warnings:
            print(f"  WARN: Box [{w['label']}] variance={w['variance']} avg={w['avg_color']}"
                  f" - may be empty")

        # Save output image
        dst_path = os.path.join(dst_dir, f"{name}.png")
        result = draw_boxes(img, calibrated)
        result.save(dst_path, quality=95)
        print(f"  -> {dst_path}")

        # Save JSON sidecar with OCR metadata
        json_path = os.path.join(dst_dir, f"{name}-ocr.json")
        json_data = {
            'name': name,
            'src': data['src'],
            'size': list(img.size),
            'mode': 'ocr',
            'boxes': [],
        }
        for cb in calibrated:
            entry = {
                'rect': list(cb['rect']),
                'label': cb['label'],
                'original': list(cb.get('_original', cb['rect'])),
            }
            if cb.get('color') and cb['color'] != RED:
                entry['color'] = 'GREEN' if cb['color'] == GREEN else 'BLUE'
            if cb.get('_delta') and any(d != 0 for d in cb['_delta']):
                entry['delta'] = list(cb['_delta'])
            if cb.get('_ocr_text'):
                entry['ocr_text'] = cb['_ocr_text']
                entry['ocr_word_count'] = cb['_ocr_count']
            if cb.get('_auto_protected'):
                entry['auto_protected'] = True
            json_data['boxes'].append(entry)
        json_data['empty_warnings'] = empty_warnings
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        print(f"  -> {json_path}")

        return calibrated

    elif mode == 'debug':
        # Detect separators for debug overlay
        content_y = 350 if img.height > 400 else 0
        h_seps = detect_all_h_separators(img, y_start=content_y)

        # Calibrate first to get delta info
        calibrated = auto_calibrate(img, boxes)

        # Draw normal boxes + debug overlay
        result = draw_boxes(img, calibrated)
        result = draw_debug_overlay(result, calibrated, h_seps)

        dst_path = os.path.join(dst_dir, f"{name}-debug.png")
        result.save(dst_path, quality=95)
        print(f"DEBUG: {dst_path} ({img.size[0]}x{img.size[1]}, "
              f"{len(boxes)} boxes, {len(h_seps)} separators)")
        return calibrated

    else:  # normal
        dst_path = os.path.join(dst_dir, f"{name}.png")

        # Fix #1: Auto-snap to edges in normal mode (disable with --no-snap)
        if snap:
            draw_target = auto_calibrate(img, boxes)
            snapped = sum(1 for b in draw_target
                          if b.get('_delta') and any(d != 0 for d in b['_delta']))
        else:
            draw_target = boxes
            snapped = 0

        # Fix #2: Check for empty/uniform boxes
        empty_warnings = check_empty_boxes(img, draw_target)
        for w in empty_warnings:
            print(f"  WARN: [{name}] Box [{w['label']}] ({w['rect']}) "
                  f"variance={w['variance']} avg={w['avg_color']} - may be empty")

        result = draw_boxes(img, draw_target)
        result.save(dst_path, quality=95)

        snap_info = f", {snapped} snapped" if snap and snapped > 0 else ""
        warn_info = f", {len(empty_warnings)} warnings" if empty_warnings else ""
        print(f"OK: {dst_path} ({img.size[0]}x{img.size[1]}, "
              f"{len(boxes)} boxes{snap_info}{warn_info})")
        return empty_warnings if empty_warnings else None


def main():
    parser = argparse.ArgumentParser(
        description='Generate annotated overlay images for PokerGFX UI Analysis and EBS Console')
    parser.add_argument('--calibrate', action='store_true',
                        help='Auto-calibrate box positions using edge detection')
    parser.add_argument('--debug', action='store_true',
                        help='Generate debug overlays with coordinates and grid')
    parser.add_argument('--no-snap', action='store_true',
                        help='Disable auto edge-snapping in normal mode')
    parser.add_argument('--ocr', action='store_true',
                        help='OCR-based precision calibration using Tesseract '
                             '(OCR text region detection + edge-snap)')
    parser.add_argument('--crop', action='store_true',
                        help='Crop each annotated box from original image')
    parser.add_argument('--ebs', action='store_true',
                        help='Process EBS Console tab mockups instead of PokerGFX')
    parser.add_argument('--target', type=str, default=None,
                        help='Process only images matching this prefix (e.g. "02" or "sources")')
    args = parser.parse_args()

    # Select image set and directories based on --ebs flag
    if args.ebs:
        if not PLAYWRIGHT_AVAILABLE:
            print("ERROR: playwright is not installed.")
            print("  Install with: pip install playwright && playwright install chromium")
            sys.exit(1)

        if args.calibrate:
            print("NOTE: --calibrate is ignored for --ebs mode. HTML coordinates are the source of truth.")

        os.makedirs(EBS_OUTPUT_DIR, exist_ok=True)
        count = 0
        for name, (html_file, tab_name, scope_filter) in EBS_HTML_MAP.items():
            if args.target and args.target not in name:
                continue

            html_path = os.path.join(EBS_INPUT_DIR, html_file)
            if not os.path.exists(html_path):
                print(f"SKIP (not found): {html_path}")
                continue

            png_name = name + '.png'
            png_path = os.path.join(EBS_OUTPUT_DIR, png_name)

            tab_info = f" [tab={tab_name}]" if tab_name else ""
            scope_info = f" [scope={scope_filter}]" if scope_filter else ""
            print(f"Processing {name} <- {html_file}{tab_info}{scope_info}")
            boxes = extract_coords_from_html(html_path, png_path, tab_name=tab_name, scope_filter=scope_filter)
            if not boxes:
                print(f"  WARNING: No [data-ann] elements found in {html_file}")
                continue

            print(f"  Extracted {len(boxes)} annotations")

            # Load the screenshot we just captured
            img = Image.open(png_path).copy()

            if args.debug:
                debug_img = img.copy()
                draw_debug_overlay(debug_img, boxes)
                debug_path = os.path.join(EBS_OUTPUT_DIR, name + '-debug.png')
                debug_img.save(debug_path)
                print(f"  Debug overlay: {debug_path}")

            # Draw annotation boxes
            img = draw_boxes(img, boxes, default_color=EBS_COLOR)

            # Check for empty boxes
            warnings = check_empty_boxes(img, boxes)
            if warnings:
                for w in warnings:
                    print(f"  WARNING: {w}")

            img.save(png_path)
            print(f"  Saved: {png_path}")
            count += 1

        print(f"\nDone: {count} EBS Console images generated (Playwright mode).")
        return
    else:
        images = IMAGES
        in_dir = INPUT_DIR
        out_dir = OUTPUT_DIR
        label = "PokerGFX"

    os.makedirs(out_dir, exist_ok=True)

    if args.crop:
        mode = 'crop'
    elif args.ocr:
        mode = 'ocr'
    elif args.calibrate:
        mode = 'calibrate'
    elif args.debug:
        mode = 'debug'
    else:
        mode = 'normal'
    snap = not args.no_snap

    if mode == 'ocr' and not TESSERACT_AVAILABLE:
        print("ERROR: pytesseract is not installed.")
        print("  Install with: pip install pytesseract")
        print("  Tesseract binary must be at: C:/Users/AidenKim/scoop/shims/tesseract.exe")
        sys.exit(1)

    count = 0
    total_warnings = 0
    total_crops = 0
    for name, data in images.items():
        if args.target and args.target not in name:
            continue
        result = process_image(name, data, mode=mode, snap=snap,
                               input_dir=in_dir, output_dir=out_dir)
        if mode == 'crop' and isinstance(result, int):
            total_crops += result
        elif isinstance(result, list):
            total_warnings += len(result)
        count += 1

    if mode == 'crop':
        print(f"\nCrop complete: {count} {label} images processed, {total_crops} crops generated.")
        print(f"Output directory: {CROP_DIR}")
    elif mode == 'ocr':
        print(f"\nOCR calibration complete: {count} {label} images processed.")
        print("OCR JSON sidecar files saved to output directory (*-ocr.json).")
    elif mode == 'calibrate':
        print(f"\nCalibration complete: {count} {label} images analyzed.")
        print("JSON sidecar files saved to output directory.")
    elif mode == 'debug':
        print(f"\nDebug overlays: {count} {label} images generated (*-debug.png).")
    else:
        warn_msg = f" ({total_warnings} empty-box warnings)" if total_warnings else ""
        snap_msg = " (edge-snap ON)" if snap else " (edge-snap OFF)"
        print(f"\nDone: {count} {label} images generated{snap_msg}{warn_msg}.")


if __name__ == '__main__':
    main()
