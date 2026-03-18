"""Skillers data models for pattern extraction and recommendation."""

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class ObservationType(str, Enum):
    """Type of observation extracted from user messages."""

    PAIN = "pain"  # Frustration, retries, errors
    REPEAT = "repeat"  # Same request across sessions
    TASK = "task"  # Recurring task type
    WISH = "wish"  # Desire for automation
    WORKFLOW = "workflow"  # Multi-step sequence


class PrimitiveType(str, Enum):
    """Type of automation primitive to recommend."""

    HOOK = "hook"
    SKILL = "skill"
    AGENT = "agent"


class Observation(BaseModel):
    """A single extracted observation from a session."""

    type: ObservationType
    content: str = Field(max_length=200)
    session_id: str
    exchange_index: int
    timestamp: datetime


class WeightedPattern(BaseModel):
    """A pattern with weighted score from multiple observations."""

    theme: str
    observations: list[Observation]
    frequency: int
    session_count: int
    last_seen: datetime
    weight: float = 0.0


class Recommendation(BaseModel):
    """A recommended automation primitive."""

    primitive: PrimitiveType
    theme: str
    reason: str
    evidence_count: int
    session_count: int
    weight: float
    existing_coverage: str | None = None
