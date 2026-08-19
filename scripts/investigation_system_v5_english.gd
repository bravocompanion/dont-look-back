extends "res://scripts/investigation_system_v4.gd"

# v0.38 English-only investigation layer.
# No runtime localization and no LanguageSystem dependency.

func _is_id() -> bool:
    return false

func _pick(_id_text: String, en_text: String) -> String:
    return en_text

func _localized_evidence_data(evidence_id: String) -> Dictionary:
    var fallback: Dictionary = Dictionary(EVIDENCE_DATA.get(evidence_id, {}))
    return {
        "title": str(fallback.get("title", evidence_id)),
        "category": str(fallback.get("category", "EVIDENCE")),
        "body": str(fallback.get("body", ""))
    }
