from workflow.task_execution import *


def _normalize_text(text: str) -> str:
    import re
    return re.sub(r"[^a-z0-9]", "", (text or "").lower())


def _find_nearby_text_button(screenshot, candidates, mask, ref_x=None, max_dx=220):
    texts = recognize_handler.detect_text_in_image(screenshot, threshold=0.35, mask=mask)
    normalized_candidates = [_normalize_text(candidate) for candidate in candidates]
    matched = []

    for item in texts:
        normalized_text = _normalize_text(item[0])
        if not normalized_text:
            continue
        if any(candidate in normalized_text or normalized_text in candidate for candidate in normalized_candidates):
            if ref_x is None or abs(item[1] - ref_x) <= max_dx:
                matched.append(item)

    if ref_x is not None:
        matched.sort(key=lambda item: (abs(item[1] - ref_x), -item[3]))
    else:
        matched.sort(key=lambda item: -item[3])
    return matched


def _click_stage_action_button(stage_pos, select_mode):
    screenshot = input_handler.capture_screenshot()
    stage_x = int(stage_pos[1])
    search_left = max(0, stage_x - 180)
    search_width = min(360, 1280 - search_left)

    if select_mode == "skip battle":
        template_hits = recognize_handler.template_match(
            screenshot,
            "skip_battle",
            threshold=0.72,
            mask=[search_left, 430, search_width, 140],
        )
        if template_hits:
            template_hits.sort(key=lambda item: abs(item[0] - stage_x))
            click_pos = (template_hits[0][0], template_hits[0][1])
            logger.info(f"[luxcavation] 识别点击 skip_battle 按钮: {click_pos}")
            input_handler.click(*click_pos)
            return True

        text_hits = _find_nearby_text_button(
            screenshot,
            ["skip battle", "skipbattle"],
            [search_left, 430, search_width, 140],
            ref_x=stage_x,
        )
        if text_hits:
            click_pos = (text_hits[0][1], text_hits[0][2])
            logger.info(f"[luxcavation] OCR 点击 skip battle 按钮: {click_pos}, 文本: {text_hits[0][0]}")
            input_handler.click(*click_pos)
            return True

        fallback = (stage_x + 10, 515)
        logger.warning(f"[luxcavation] 未识别到 skip battle，回退点击 {fallback}")
        input_handler.click(*fallback)
        return True

    if select_mode == "enter":
        text_hits = _find_nearby_text_button(
            screenshot,
            ["enter", "start"],
            [search_left, 430, search_width, 120],
            ref_x=stage_x,
        )
        if text_hits:
            click_pos = (text_hits[0][1], text_hits[0][2])
            logger.info(f"[luxcavation] OCR 点击 enter 按钮: {click_pos}, 文本: {text_hits[0][0]}")
            input_handler.click(*click_pos)
            return True

        fallback = (stage_x + 10, 480)
        logger.warning(f"[luxcavation] 未识别到 enter，回退点击 {fallback}")
        input_handler.click(*fallback)
        return True

    raise Exception(f"未知的 luxcavation mode：{select_mode}")



@TaskExecution.register("exp_select_stage")
def exec_exp_select_stage(self, node: TaskNode, func):
    logger.info("选择经验副本关卡", input_handler.capture_screenshot())
    cfg = self._get_using_cfg("exp")
    target_stage = cfg["exp_stage"]
    pos = recognize_handler.find_text_in_image(input_handler.capture_screenshot(), target_stage, mask=[250, 180, 1000, 50])
    if len(pos) == 0:
        # 经验本高等级关卡位于右侧，优先向左滑动以显示更右边的关卡。
        # 若仍未找到，则再反向回退搜索，避免因当前初始位置不同导致卡死。
        swipe_plans = [
            (940, 310, 590, 310, 6),
            (590, 310, 940, 310, 3),
        ]

        for start_x, start_y, end_x, end_y, max_retry in swipe_plans:
            for _ in range(max_retry):
                input_handler.swipe(start_x, start_y, end_x, end_y)
                time.sleep(0.6)
                pos = recognize_handler.find_text_in_image(
                    input_handler.capture_screenshot(),
                    target_stage,
                    mask=[250, 180, 1000, 50],
                )
                if len(pos) > 0:
                    break
            if len(pos) > 0:
                break

    if len(pos) == 0:
        raise Exception(f"未找到经验副本关卡：{target_stage}")

    select_mode = cfg["luxcavation_mode"]
    _click_stage_action_button(pos[0], select_mode)

    


@TaskExecution.register("thread_select_stage")
def exec_thread_select_stage(self, node: TaskNode, func):
    logger.info("选择Thread副本关卡", input_handler.capture_screenshot())
    thread_tab = _find_nearby_text_button(
        input_handler.capture_screenshot(),
        ["thread"],
        [40, 250, 220, 180],
    )
    if thread_tab:
        input_handler.click(thread_tab[0][1], thread_tab[0][2])
    else:
        input_handler.click(140, 330)
    time.sleep(1)
    cfg = self._get_using_cfg("thread")
    select_mode = cfg["luxcavation_mode"]

    mode_button = _find_nearby_text_button(
        input_handler.capture_screenshot(),
        ["enter"] if select_mode == "enter" else ["skip battle", "skipbattle"],
        [250, 430, 260, 120],
    )
    if mode_button:
        input_handler.click(mode_button[0][1], mode_button[0][2])
    elif select_mode == "enter":
        input_handler.click(370, 480)
    elif select_mode == "skip battle":
        input_handler.click(370, 515)
    else:
        raise Exception(f"未知的 thread mode：{select_mode}")
    time.sleep(1)

    target_stage = cfg["thread_stage"]
    pos = recognize_handler.find_text_in_image(input_handler.capture_screenshot(), target_stage, mask=[610, 170, 90, 400])
    while len(pos) == 0:
        input_handler.swipe(650, 325, 650, 430)
        time.sleep(0.6)
        pos = recognize_handler.find_text_in_image(input_handler.capture_screenshot(), target_stage, mask=[610, 170, 90, 400])

    input_handler.click(pos[0][1], pos[0][2])

    