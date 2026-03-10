import os
import time
import random
import platform
from dataclasses import dataclass
from typing import Tuple, Optional

from AppKit import NSApplicationActivateIgnoringOtherApps, NSWorkspace
from PIL import Image, ImageGrab, ImageFilter
from pynput.mouse import Controller as MouseController, Button
from pynput.keyboard import Controller as KeyboardController, Key
from Quartz import (
    CGEventCreateKeyboardEvent,
    CGEventCreateMouseEvent,
    CGEventPost,
    CGPointMake,
    kCGEventLeftMouseDown,
    kCGEventLeftMouseDragged,
    kCGEventLeftMouseUp,
    kCGEventMouseMoved,
    kCGEventKeyDown,
    kCGEventKeyUp,
    kCGHIDEventTap,
    kCGMouseButtonLeft,
)


@dataclass
class MacWindow:
    left: int
    top: int
    width: int
    height: int
    logical_width: int = 1302
    logical_height: int = 776


_mouse = MouseController()
_keyboard = KeyboardController()
_LAST_FOCUS_TS = 0.0
_FOCUS_COOLDOWN_SEC = 10.0  # 延长冷却时间到10秒，减少授权弹窗


_CLICK_JITTER = 0
_CLICK_OFFSET_X = 0
_CLICK_OFFSET_Y = 0
_CLIENT_INSET_LEFT = 0
_CLIENT_INSET_TOP = 0
_CLIENT_INSET_RIGHT = 0
_CLIENT_INSET_BOTTOM = 0
_CLIENT_BOX_MODE = "full"


_MAC_KEYCODE_MAP = {
    "enter": 36,
    "esc": 53,
    "space": 49,
    "p": 35,
}


def _activate_process(name: str) -> bool:
    if not name:
        return False

    try:
        for app in NSWorkspace.sharedWorkspace().runningApplications():
            localized_name = app.localizedName() or ""
            if name.lower() in localized_name.lower():
                return bool(
                    app.activateWithOptions_(NSApplicationActivateIgnoringOtherApps)
                )
    except Exception:
        return False

    return False


def _focus_game_app() -> bool:
    global _LAST_FOCUS_TS

    now = time.monotonic()
    if now - _LAST_FOCUS_TS < _FOCUS_COOLDOWN_SEC:
        return True

    candidates = []

    env_candidates = os.getenv("LALC_MAC_FOCUS_APPS", "")
    if env_candidates.strip():
        candidates.extend([x.strip() for x in env_candidates.split(",") if x.strip()])

    candidates.extend([
        "CrossOver",
        "LimbusCompany.exe",
        "LimbusCompany",
        "Wine",
    ])

    seen = set()
    ordered = []
    for candidate in candidates:
        if candidate not in seen:
            seen.add(candidate)
            ordered.append(candidate)

    for candidate in ordered:
        if _activate_process(candidate):
            _LAST_FOCUS_TS = time.monotonic()
            time.sleep(0.2)
            return True

    return False


def _post_mouse_event(event_type, x: int, y: int):
    event = CGEventCreateMouseEvent(
        None,
        event_type,
        CGPointMake(float(x), float(y)),
        kCGMouseButtonLeft,
    )
    CGEventPost(kCGHIDEventTap, event)


def _quartz_click(x: int, y: int):
    _post_mouse_event(kCGEventMouseMoved, x, y)
    time.sleep(0.02)
    _post_mouse_event(kCGEventLeftMouseDown, x, y)
    time.sleep(0.05)
    _post_mouse_event(kCGEventLeftMouseUp, x, y)


def _quartz_press(x: int, y: int):
    _post_mouse_event(kCGEventMouseMoved, x, y)
    time.sleep(0.02)
    _post_mouse_event(kCGEventLeftMouseDown, x, y)


def _quartz_release(x: int, y: int):
    _post_mouse_event(kCGEventMouseMoved, x, y)
    time.sleep(0.01)
    _post_mouse_event(kCGEventLeftMouseUp, x, y)


def _quartz_swipe(start_x: int, start_y: int, end_x: int, end_y: int, speed=1):
    _post_mouse_event(kCGEventMouseMoved, start_x, start_y)
    time.sleep(0.02)
    _post_mouse_event(kCGEventLeftMouseDown, start_x, start_y)
    steps = max(10, int(40 / max(0.2, speed)))
    for i in range(1, steps + 1):
        nx = int(start_x + (end_x - start_x) * i / steps)
        ny = int(start_y + (end_y - start_y) * i / steps)
        _post_mouse_event(kCGEventLeftMouseDragged, nx, ny)
        time.sleep(0.004)
    _post_mouse_event(kCGEventLeftMouseUp, end_x, end_y)


def _quartz_key_press(key, duration=0.05):
    mapped = _map_key(key)
    if isinstance(mapped, str):
        keycode = _MAC_KEYCODE_MAP.get(mapped.lower())
    else:
        keycode = _MAC_KEYCODE_MAP.get(str(key).lower())

    if keycode is None:
        # 退回到 pynput
        _keyboard.press(mapped)
        time.sleep(duration + random.random() * 0.05)
        _keyboard.release(mapped)
        return True

    down = CGEventCreateKeyboardEvent(None, keycode, True)
    up = CGEventCreateKeyboardEvent(None, keycode, False)
    CGEventPost(kCGHIDEventTap, down)
    time.sleep(duration + random.random() * 0.05)
    CGEventPost(kCGHIDEventTap, up)
    return True


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return default


def _load_runtime_tuning():
    global _CLICK_JITTER, _CLICK_OFFSET_X, _CLICK_OFFSET_Y
    global _CLIENT_INSET_LEFT, _CLIENT_INSET_TOP, _CLIENT_INSET_RIGHT, _CLIENT_INSET_BOTTOM
    global _CLIENT_BOX_MODE
    _CLICK_JITTER = max(0, _env_int("LALC_CLICK_JITTER", 0))
    _CLICK_OFFSET_X = _env_int("LALC_CLICK_OFFSET_X", 0)
    _CLICK_OFFSET_Y = _env_int("LALC_CLICK_OFFSET_Y", 0)
    _CLIENT_INSET_LEFT = _env_int("LALC_CLIENT_INSET_LEFT", 0)
    _CLIENT_INSET_TOP = _env_int("LALC_CLIENT_INSET_TOP", 0)
    _CLIENT_INSET_RIGHT = _env_int("LALC_CLIENT_INSET_RIGHT", 0)
    _CLIENT_INSET_BOTTOM = _env_int("LALC_CLIENT_INSET_BOTTOM", 0)
    _CLIENT_BOX_MODE = os.getenv("LALC_CLIENT_BOX_MODE", "full").strip().lower() or "full"


def _auto_detect_window() -> Optional[Tuple[int, int, int, int]]:
    """尝试自动检测CrossOver游戏窗口"""
    try:
        from utils.window_detector import detect_window_bounds
        
        # 尝试检测LimbusCompany窗口
        bounds = detect_window_bounds("LimbusCompany")
        if bounds:
            return bounds
        
        # 如果没找到，尝试检测CrossOver窗口
        bounds = detect_window_bounds("CrossOver")
        if bounds:
            return bounds
            
    except Exception as e:
        print(f"自动检测窗口失败: {e}")
    
    return None


def _default_window() -> MacWindow:
    """初始化窗口配置，优先级：环境变量 > 自动检测 > 默认值"""
    
    # 检查是否设置了环境变量
    has_env = any(os.getenv(k) for k in [
        "LALC_WINDOW_LEFT", "LALC_WINDOW_TOP", 
        "LALC_WINDOW_WIDTH", "LALC_WINDOW_HEIGHT"
    ])
    
    if has_env:
        # 使用环境变量配置
        return MacWindow(
            left=_env_int("LALC_WINDOW_LEFT", 0),
            top=_env_int("LALC_WINDOW_TOP", 0),
            width=_env_int("LALC_WINDOW_WIDTH", 1302),
            height=_env_int("LALC_WINDOW_HEIGHT", 776),
            logical_width=1302,
            logical_height=776,
        )
    
    # 尝试自动检测
    detected = _auto_detect_window()
    if detected:
        print(f"✓ 自动检测到游戏窗口: left={detected[0]}, top={detected[1]}, width={detected[2]}, height={detected[3]}")
        return MacWindow(
            left=detected[0],
            top=detected[1],
            width=detected[2],
            height=detected[3],
            logical_width=1302,
            logical_height=776,
        )
    
    # 使用默认值
    print("⚠️  未检测到游戏窗口，使用默认配置。如需手动指定，请设置环境变量：")
    print("   export LALC_WINDOW_LEFT=0 LALC_WINDOW_TOP=0 LALC_WINDOW_WIDTH=1302 LALC_WINDOW_HEIGHT=776")
    return MacWindow(
        left=0,
        top=0,
        width=1302,
        height=776,
        logical_width=1302,
        logical_height=776,
    )


_WINDOW = _default_window()
_load_runtime_tuning()
_IS_APPLE_SILICON = platform.system() == "Darwin" and platform.machine().lower() in {"arm64", "aarch64"}


def _get_logical_client_rect(hwnd):
    return hwnd.logical_width, hwnd.logical_height


def _get_client_box(hwnd) -> Tuple[int, int, int, int]:
    """计算真实游戏客户区。

    默认使用 full 模式（整个窗口 + 边距微调），更适合 CrossOver 与高分辨率场景。
    可选 ratio 模式兼容旧逻辑（按逻辑分辨率宽高比推算）。

    返回值: (client_left, client_top, client_width, client_height)
    """
    actual_w = max(1, int(hwnd.width))
    actual_h = max(1, int(hwnd.height))

    if _CLIENT_BOX_MODE == "ratio":
        logical_w = max(1, int(hwnd.logical_width))
        logical_h = max(1, int(hwnd.logical_height))
        actual_ratio = actual_w / actual_h
        logical_ratio = logical_w / logical_h

        if actual_ratio > logical_ratio:
            client_h = actual_h
            client_w = int(round(client_h * logical_ratio))
            offset_x = max(0, (actual_w - client_w) // 2)
            offset_y = 0
        elif actual_ratio < logical_ratio:
            client_w = actual_w
            client_h = int(round(client_w / logical_ratio))
            offset_x = 0
            offset_y = max(0, (actual_h - client_h) // 2)
        else:
            client_w = actual_w
            client_h = actual_h
            offset_x = 0
            offset_y = 0

        client_left = int(hwnd.left + offset_x)
        client_top = int(hwnd.top + offset_y)
    else:
        # full 模式：不做比例裁切，直接使用窗口区域
        client_left = int(hwnd.left)
        client_top = int(hwnd.top)
        client_w = int(actual_w)
        client_h = int(actual_h)

    # 统一应用边距微调（可用于去掉标题栏/边框）
    client_left += _CLIENT_INSET_LEFT
    client_top += _CLIENT_INSET_TOP
    client_w = max(1, client_w - _CLIENT_INSET_LEFT - _CLIENT_INSET_RIGHT)
    client_h = max(1, client_h - _CLIENT_INSET_TOP - _CLIENT_INSET_BOTTOM)

    return (client_left, client_top, client_w, client_h)


def _to_screen(hwnd, x, y) -> Tuple[int, int]:
    client_left, client_top, client_width, client_height = _get_client_box(hwnd)
    scale_x = client_width / max(1, hwnd.logical_width)
    scale_y = client_height / max(1, hwnd.logical_height)
    return (
        int(client_left + x * scale_x) + _CLICK_OFFSET_X,
        int(client_top + y * scale_y) + _CLICK_OFFSET_Y,
    )


def _refresh_window_bounds(hwnd):
    """在每次交互前刷新窗口位置，避免窗口移动后点击漂移。"""
    try:
        detected = _auto_detect_window()
        if detected:
            hwnd.left = int(detected[0])
            hwnd.top = int(detected[1])
            hwnd.width = int(detected[2])
            hwnd.height = int(detected[3])
    except Exception:
        pass


def find_game_window(window_title="LimbusCompany", window_class="UnityWndClass"):
    return _WINDOW


def set_window_size(hwnd, width=1302, height=776):
    hwnd.logical_width = int(width)
    hwnd.logical_height = int(height)


def set_window_position(hwnd, x, y):
    hwnd.left = int(x)
    hwnd.top = int(y)


def set_window_to_top(hwnd, client_width=1280, client_height=720):
    hwnd.left = 0
    hwnd.top = 0
    hwnd.logical_width = int(client_width)
    hwnd.logical_height = int(client_height)


def set_background_focus(hwnd) -> bool:
    return _focus_game_app()


def set_foreground_focus(hwnd) -> bool:
    return _focus_game_app()


def get_cursor_pos():
    p = _mouse.position
    return int(p[0]), int(p[1])


def is_mouse_in_window(hwnd):
    x, y = get_cursor_pos()
    inside = hwnd.left <= x <= (hwnd.left + hwnd.width) and hwnd.top <= y <= (hwnd.top + hwnd.height)
    return inside, x, y


def move_mouse_to_top_right_corner(hwnd):
    _mouse.position = (hwnd.left + hwnd.width + 10, max(0, hwnd.top - 5))


def close_window(hwnd):
    return False


def close_limbus_window(window_title="LimbusCompany", window_class="UnityWndClass"):
    return False


def take_screenshot(hwnd, width=None, height=None, save_path=None):
    _refresh_window_bounds(hwnd)
    if width is None or height is None:
        width, height = _get_logical_client_rect(hwnd)
    client_left, client_top, client_width, client_height = _get_client_box(hwnd)
    bbox = (
        int(client_left),
        int(client_top),
        int(client_left + client_width),
        int(client_top + client_height),
    )
    img = ImageGrab.grab(bbox=bbox)
    if img.size != (int(width), int(height)):
        img = img.resize((int(width), int(height)), resample=Image.Resampling.LANCZOS)
    if _IS_APPLE_SILICON:
        img = img.filter(ImageFilter.UnsharpMask(radius=1.2, percent=135, threshold=2))
    if save_path:
        img.save(save_path)
    return img


def background_click(hwnd, x, y):
    _focus_game_app()
    _refresh_window_bounds(hwnd)
    jitter_x = random.randint(-_CLICK_JITTER, _CLICK_JITTER) if _CLICK_JITTER > 0 else 0
    jitter_y = random.randint(-_CLICK_JITTER, _CLICK_JITTER) if _CLICK_JITTER > 0 else 0
    sx, sy = _to_screen(hwnd, x + jitter_x, y + jitter_y)
    _mouse.position = (sx, sy)
    time.sleep(0.03)
    _quartz_click(sx, sy)
    return True


def foreground_click(hwnd, x, y):
    return background_click(hwnd, x, y)


def background_press(hwnd, x, y):
    _focus_game_app()
    _refresh_window_bounds(hwnd)
    sx, sy = _to_screen(hwnd, x, y)
    _mouse.position = (sx, sy)
    time.sleep(0.03)
    _quartz_press(sx, sy)
    return True


def background_release(hwnd, x, y):
    _focus_game_app()
    _refresh_window_bounds(hwnd)
    sx, sy = _to_screen(hwnd, x, y)
    _mouse.position = (sx, sy)
    time.sleep(0.02)
    _quartz_release(sx, sy)
    return True


def foreground_press(hwnd, x, y):
    return background_press(hwnd, x, y)


def foreground_release(hwnd, x, y):
    return background_release(hwnd, x, y)


def background_long_press(hwnd, x, y, duration=3):
    background_press(hwnd, x, y)
    time.sleep(duration)
    background_release(hwnd, x, y)
    return True


def foreground_long_press(hwnd, x, y, duration=3):
    return background_long_press(hwnd, x, y, duration)


_KEY_MAP = {
    "enter": Key.enter,
    "esc": Key.esc,
    "space": Key.space,
}


def _map_key(key):
    if isinstance(key, str):
        low = key.lower()
        if low in _KEY_MAP:
            return _KEY_MAP[low]
        if len(low) == 1:
            return low
    return key


def background_key_press(hwnd, key, duration=0.05):
    _focus_game_app()
    return _quartz_key_press(key, duration)


def foreground_key_press(hwnd, key, duration=0.05):
    _focus_game_app()
    return _quartz_key_press(key, duration)


def background_swipe(hwnd, start_x, start_y, end_x, end_y, speed=1):
    _focus_game_app()
    _refresh_window_bounds(hwnd)
    sx, sy = _to_screen(hwnd, start_x, start_y)
    ex, ey = _to_screen(hwnd, end_x, end_y)
    _mouse.position = (sx, sy)
    time.sleep(0.03)
    _quartz_swipe(sx, sy, ex, ey, speed)
    return True


def foreground_swipe(hwnd, start_x, start_y, end_x, end_y, speed=0.25):
    return background_swipe(hwnd, start_x, start_y, end_x, end_y, speed)
