import os
import time
import random
from dataclasses import dataclass
from typing import Tuple, Optional

from PIL import ImageGrab
from pynput.mouse import Controller as MouseController, Button
from pynput.keyboard import Controller as KeyboardController, Key


@dataclass
class MacWindow:
    left: int
    top: int
    width: int
    height: int


_mouse = MouseController()
_keyboard = KeyboardController()


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return default


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
        )
    
    # 使用默认值
    print("⚠️  未检测到游戏窗口，使用默认配置。如需手动指定，请设置环境变量：")
    print("   export LALC_WINDOW_LEFT=0 LALC_WINDOW_TOP=0 LALC_WINDOW_WIDTH=1302 LALC_WINDOW_HEIGHT=776")
    return MacWindow(
        left=0,
        top=0,
        width=1302,
        height=776,
    )


_WINDOW = _default_window()


def _get_logical_client_rect(hwnd):
    return hwnd.width, hwnd.height


def _to_screen(hwnd, x, y) -> Tuple[int, int]:
    return int(hwnd.left + x), int(hwnd.top + y)


def find_game_window(window_title="LimbusCompany", window_class="UnityWndClass"):
    return _WINDOW


def set_window_size(hwnd, width=1302, height=776):
    hwnd.width = int(width)
    hwnd.height = int(height)


def set_window_position(hwnd, x, y):
    hwnd.left = int(x)
    hwnd.top = int(y)


def set_window_to_top(hwnd, client_width=1280, client_height=720):
    hwnd.left = 0
    hwnd.top = 0
    hwnd.width = int(client_width)
    hwnd.height = int(client_height)


def set_background_focus(hwnd) -> bool:
    return False


def set_foreground_focus(hwnd) -> bool:
    return False


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
    if width is None or height is None:
        width, height = _get_logical_client_rect(hwnd)
    bbox = (int(hwnd.left), int(hwnd.top), int(hwnd.left + width), int(hwnd.top + height))
    img = ImageGrab.grab(bbox=bbox)
    if save_path:
        img.save(save_path)
    return img


def background_click(hwnd, x, y):
    sx, sy = _to_screen(hwnd, x + random.randint(-3, 3), y + random.randint(-3, 3))
    _mouse.position = (sx, sy)
    _mouse.click(Button.left, 1)
    return True


def foreground_click(hwnd, x, y):
    return background_click(hwnd, x, y)


def background_press(hwnd, x, y):
    sx, sy = _to_screen(hwnd, x, y)
    _mouse.position = (sx, sy)
    _mouse.press(Button.left)
    return True


def background_release(hwnd, x, y):
    sx, sy = _to_screen(hwnd, x, y)
    _mouse.position = (sx, sy)
    _mouse.release(Button.left)
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
    k = _map_key(key)
    _keyboard.press(k)
    time.sleep(duration + random.random() * 0.05)
    _keyboard.release(k)
    return True


def foreground_key_press(key, duration=0.05):
    k = _map_key(key)
    _keyboard.press(k)
    time.sleep(duration + random.random() * 0.05)
    _keyboard.release(k)
    return True


def background_swipe(hwnd, start_x, start_y, end_x, end_y, speed=1):
    sx, sy = _to_screen(hwnd, start_x, start_y)
    ex, ey = _to_screen(hwnd, end_x, end_y)
    _mouse.position = (sx, sy)
    _mouse.press(Button.left)
    steps = max(10, int(40 / max(0.2, speed)))
    for i in range(1, steps + 1):
        nx = int(sx + (ex - sx) * i / steps)
        ny = int(sy + (ey - sy) * i / steps)
        _mouse.position = (nx, ny)
        time.sleep(0.003)
    _mouse.release(Button.left)
    return True


def foreground_swipe(hwnd, start_x, start_y, end_x, end_y, speed=0.25):
    return background_swipe(hwnd, start_x, start_y, end_x, end_y, speed)
