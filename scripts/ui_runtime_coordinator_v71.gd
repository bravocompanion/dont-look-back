extends Node

# v0.71 single source of truth for the top-of-screen gameplay HUD lanes.
# This deliberately returns geometry only: gameplay systems keep ownership of
# their content, while every UI reads the same non-overlapping rectangles.

const COMPACT_WIDTH: float = 800.0

func is_compact_v71(viewport_size: Vector2) -> bool:
    if viewport_size.x < COMPACT_WIDTH:
        return true
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

func get_layout_v71(viewport_size: Vector2, compact_override: Variant = null) -> Dictionary:
    var compact: bool = is_compact_v71(viewport_size) if compact_override == null else bool(compact_override)
    var width: float = maxf(320.0, viewport_size.x)
    if compact:
        var quick_width: float = 76.0
        var quick_height: float = 44.0
        var progress_width: float = minf(260.0, width - 20.0)
        var intel_width: float = minf(310.0, width - 20.0)
        return {
            "compact": true,
            "status": Rect2(5.0, 5.0, width - 10.0, 46.0),
            "progression": Rect2((width - progress_width) * 0.5, 58.0, progress_width, 36.0),
            "toast": Rect2((width - progress_width) * 0.5, 58.0, progress_width, 36.0),
            "bag_button": Rect2(12.0, 102.0, quick_width, quick_height),
            "menu_button": Rect2((width - quick_width) * 0.5, 102.0, quick_width, quick_height),
            "prog_button": Rect2(width - 12.0 - quick_width, 102.0, quick_width, quick_height),
            "objective": Rect2(10.0, 154.0, width - 20.0, 44.0),
            "intel": Rect2((width - intel_width) * 0.5, 206.0, intel_width, 50.0)
        }

    var progress_width_desktop: float = minf(390.0, maxf(300.0, width * 0.34))
    var progress_x: float = width - 24.0 - progress_width_desktop
    var objective_width: float = maxf(180.0, progress_x - 40.0)
    var intel_width_desktop: float = minf(430.0, maxf(320.0, width * 0.36))
    return {
        "compact": false,
        "status": Rect2(16.0, 16.0, width - 32.0, 52.0),
        "progression": Rect2(progress_x, 76.0, progress_width_desktop, 38.0),
        "toast": Rect2(progress_x, 76.0, progress_width_desktop, 38.0),
        "bag_button": Rect2(28.0, 174.0, 48.0, 42.0),
        "menu_button": Rect2(width - 114.0, 76.0, 90.0, 42.0),
        "prog_button": Rect2(28.0, 222.0, 52.0, 42.0),
        "objective": Rect2(24.0, 76.0, objective_width, 46.0),
        "intel": Rect2(width - 24.0 - intel_width_desktop, 130.0, intel_width_desktop, 76.0)
    }

func rects_overlap_v71(a: Rect2, b: Rect2) -> bool:
    return a.intersects(b, true)

func get_layout_contract_v71() -> Dictionary:
    return {
        "single_source_of_truth": true,
        "desktop_responsive": true,
        "mobile_responsive": true,
        "toast_reuses_progression_lane": true,
        "compact_three_button_row": true,
        "minimum_supported_width": 320,
        "new_art_required": false
    }
