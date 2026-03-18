"""Primitive classification (hook vs skill vs agent)."""

from models import ObservationType, PrimitiveType, WeightedPattern


def classify_primitive(pattern: WeightedPattern) -> PrimitiveType:
    """
    Classify what automation primitive to suggest.

    Decision rules:
    - workflowRatio >= 0.5 → hook (no judgment needed)
    - painRatio >= 0.4 → agent (needs context)
    - taskRatio >= 0.3 → skill (multi-step procedure)
    - default → skill
    """
    if not pattern.observations:
        return PrimitiveType.SKILL

    total = len(pattern.observations)
    type_counts: dict[ObservationType, int] = {}
    for obs in pattern.observations:
        type_counts[obs.type] = type_counts.get(obs.type, 0) + 1

    workflow_ratio = type_counts.get(ObservationType.WORKFLOW, 0) / total
    pain_ratio = (
        type_counts.get(ObservationType.PAIN, 0) + type_counts.get(ObservationType.WISH, 0)
    ) / total
    task_ratio = type_counts.get(ObservationType.TASK, 0) / total

    if workflow_ratio >= 0.5:
        return PrimitiveType.HOOK
    if pain_ratio >= 0.4:
        return PrimitiveType.AGENT
    if task_ratio >= 0.3:
        return PrimitiveType.SKILL

    return PrimitiveType.SKILL
