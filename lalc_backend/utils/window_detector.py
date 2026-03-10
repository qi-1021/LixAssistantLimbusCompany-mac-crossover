"""
macOS窗口检测工具
用于自动检测CrossOver中运行的游戏窗口位置
"""

import os
import sys
from typing import Optional, Tuple, List


_BROWSER_OWNERS = {
    "quark",
    "google chrome",
    "microsoft edge",
    "safari",
    "firefox",
    "arc",
    "opera",
    "brave browser",
    "brave",
}


def _looks_like_browser_or_document(owner: str, name: str) -> bool:
    owner_lower = owner.lower().strip()
    name_lower = name.lower().strip()

    if owner_lower in _BROWSER_OWNERS:
        return True

    suspicious_tokens = [
        "github",
        "gitlab",
        "contributing.md",
        "readme",
        "doc/",
        "docs/",
        ".md",
        "http://",
        "https://",
    ]
    return any(token in name_lower for token in suspicious_tokens)


def detect_window_bounds(window_title: str = "LimbusCompany") -> Optional[Tuple[int, int, int, int]]:
    """
    检测窗口边界（left, top, width, height）
    
    Args:
        window_title: 窗口标题包含的关键字
    
    Returns:
        (left, top, width, height) 或 None（如果未找到）
    """
    try:
        # 尝试使用pyobjc-framework-Quartz
        from Quartz import (
            CGWindowListCopyWindowInfo,
            kCGWindowListOptionOnScreenOnly,
            kCGNullWindowID,
        )
        
        window_list = CGWindowListCopyWindowInfo(
            kCGWindowListOptionOnScreenOnly,
            kCGNullWindowID
        )
        
        candidates = []
        
        for window in window_list:
            name = window.get('kCGWindowName', '')
            owner = window.get('kCGWindowOwnerName', '')
            bounds = window.get('kCGWindowBounds')
            
            # 跳过没有边界信息的窗口
            if not bounds:
                continue
            
            left = int(bounds['X'])
            top = int(bounds['Y'])
            width = int(bounds['Width'])
            height = int(bounds['Height'])
            
            # 过滤掉太小的窗口（可能是工具栏等）
            if width < 200 or height < 200:
                continue
            
            # 计算匹配分数（owner 精确匹配优先级最高）
            score = 0
            owner_lower = owner.lower()
            name_lower = name.lower()
            keyword_lower = window_title.lower()

            if _looks_like_browser_or_document(owner, name):
                continue
            
            # 应用名称精确匹配（如 LimbusCompany.exe）
            if keyword_lower in owner_lower:
                score += 100
            
            # CrossOver 窗口额外加分
            if 'crossover' in owner_lower:
                score += 50
            
            # 窗口标题匹配（优先级较低，避免误匹配浏览器标题）
            if keyword_lower in name_lower:
                score += 10

            # 对游戏常见标题进一步加分，优先于普通 CrossOver 宿主窗口
            if any(token in name_lower for token in ['limbuscompany', 'limbus company', '边狱巴士']):
                score += 40

            # 仅凭标题弱匹配时要求宿主也可信，避免误抓其它普通窗口
            if score > 0 and score <= 10 and 'crossover' not in owner_lower and keyword_lower not in owner_lower:
                continue
            
            # 必须有匹配才加入候选
            if score > 0:
                candidates.append({
                    'name': name,
                    'owner': owner,
                    'bounds': (left, top, width, height),
                    'area': width * height,
                    'score': score
                })
        
        if not candidates:
            return None
        
        # 先按匹配分数排序，分数相同时按面积排序
        candidates.sort(key=lambda x: (x['score'], x['area']), reverse=True)
        best = candidates[0]
        
        print(f"检测到窗口: {best['owner']} - {best['name']}")
        print(f"位置: {best['bounds']} (匹配分数: {best['score']})")
        
        return best['bounds']
        
    except ImportError:
        print("警告: 未安装 pyobjc-framework-Quartz，无法自动检测窗口", file=sys.stderr)
        print("请运行: pip install pyobjc-framework-Quartz", file=sys.stderr)
        return None
    except Exception as e:
        print(f"窗口检测失败: {e}", file=sys.stderr)
        return None


def list_all_windows() -> List[dict]:
    """
    列出所有可见窗口（用于调试）
    
    Returns:
        窗口信息列表
    """
    try:
        from Quartz import (
            CGWindowListCopyWindowInfo,
            kCGWindowListOptionOnScreenOnly,
            kCGNullWindowID,
        )
        
        window_list = CGWindowListCopyWindowInfo(
            kCGWindowListOptionOnScreenOnly,
            kCGNullWindowID
        )
        
        result = []
        for window in window_list:
            name = window.get('kCGWindowName', '')
            owner = window.get('kCGWindowOwnerName', '')
            bounds = window.get('kCGWindowBounds')
            
            if bounds and bounds['Width'] > 100 and bounds['Height'] > 100:
                result.append({
                    'name': name,
                    'owner': owner,
                    'bounds': (
                        int(bounds['X']),
                        int(bounds['Y']),
                        int(bounds['Width']),
                        int(bounds['Height'])
                    )
                })
        
        return result
        
    except ImportError:
        print("错误: 未安装 pyobjc-framework-Quartz", file=sys.stderr)
        return []
    except Exception as e:
        print(f"列举窗口失败: {e}", file=sys.stderr)
        return []


if __name__ == "__main__":
    # 命令行工具：检测窗口或列出所有窗口
    import argparse
    
    parser = argparse.ArgumentParser(description="macOS窗口检测工具")
    parser.add_argument("--list", action="store_true", help="列出所有窗口")
    parser.add_argument("--detect", type=str, help="检测包含指定关键字的窗口")
    
    args = parser.parse_args()
    
    if args.list:
        windows = list_all_windows()
        print(f"\n找到 {len(windows)} 个窗口:\n")
        for i, win in enumerate(windows, 1):
            print(f"{i}. {win['owner']}")
            if win['name']:
                print(f"   标题: {win['name']}")
            print(f"   位置: x={win['bounds'][0]}, y={win['bounds'][1]}, w={win['bounds'][2]}, h={win['bounds'][3]}\n")
    
    elif args.detect:
        bounds = detect_window_bounds(args.detect)
        if bounds:
            print(f"\n找到窗口:")
            print(f"  LALC_WINDOW_LEFT={bounds[0]}")
            print(f"  LALC_WINDOW_TOP={bounds[1]}")
            print(f"  LALC_WINDOW_WIDTH={bounds[2]}")
            print(f"  LALC_WINDOW_HEIGHT={bounds[3]}")
            print(f"\n可以这样使用:")
            print(f"  export LALC_WINDOW_LEFT={bounds[0]} LALC_WINDOW_TOP={bounds[1]} LALC_WINDOW_WIDTH={bounds[2]} LALC_WINDOW_HEIGHT={bounds[3]}")
        else:
            print(f"\n未找到包含 '{args.detect}' 的窗口")
            sys.exit(1)
    
    else:
        parser.print_help()
