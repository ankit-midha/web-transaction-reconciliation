"""NMI parser module with integrated checksum validation.

This module provides functions to parse and validate National Metering
Identifiers (NMIs) used in Australian energy systems, including checksum
validation using the AEMO standard Luhn-like algorithm.
"""

from typing import Optional, Dict, Any
from src.nmi_checksum import validate_nmi_checksum


def parse_nmi(nmi: Optional[str]) -> Optional[Dict[str, Any]]:
    """Parse and validate an NMI string.

    Returns a dictionary with parsing results if the NMI has valid format,
    or None if the format is invalid (wrong length, non-digits, etc.).

    The returned dictionary includes:
    - nmi: The original NMI string
    - valid: Whether the checksum is valid (True for 10-digit, validated for 11-digit)
    - has_checksum: Whether the NMI includes a checksum digit (11-digit format)

    Args:
        nmi: The NMI string to parse (10 or 11 digits)

    Returns:
        A dictionary with parsing results, or None if format is invalid

    Examples:
        >>> parse_nmi("1234567890")
        {'nmi': '1234567890', 'valid': True, 'has_checksum': False}

        >>> parse_nmi("12345678903")
        {'nmi': '12345678903', 'valid': True, 'has_checksum': True}

        >>> parse_nmi("12345678904")
        {'nmi': '12345678904', 'valid': False, 'has_checksum': True}

        >>> parse_nmi("123")
        None
    """
    if nmi is None:
        return None

    if not isinstance(nmi, str):
        return None

    # Check basic format requirements
    if len(nmi) not in (10, 11):
        return None

    if not nmi.isdigit():
        return None

    # Validate checksum
    is_valid = validate_nmi_checksum(nmi)
    has_checksum = len(nmi) == 11

    return {
        "nmi": nmi,
        "valid": is_valid,
        "has_checksum": has_checksum,
    }


def is_valid_nmi(nmi: Optional[str]) -> bool:
    """Check if an NMI is valid.

    This is a simplified validation function that returns True if the NMI
    has valid format and passes checksum validation, False otherwise.

    Args:
        nmi: The NMI string to validate (10 or 11 digits)

    Returns:
        True if the NMI is valid, False otherwise

    Examples:
        >>> is_valid_nmi("1234567890")
        True

        >>> is_valid_nmi("12345678903")
        True

        >>> is_valid_nmi("12345678904")
        False

        >>> is_valid_nmi("123")
        False
    """
    result = parse_nmi(nmi)
    if result is None:
        return False
    return result["valid"]
