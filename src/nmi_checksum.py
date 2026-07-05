"""NMI checksum validation using AEMO standard Luhn-like algorithm.

The AEMO Luhn-like algorithm (Modulus 10, Double Add Double) is used to
validate National Metering Identifiers (NMIs) in Australian energy systems.
"""


def calculate_checksum(nmi_base: str) -> int:
    """Calculate the AEMO Luhn-like checksum for a 10-digit NMI base.

    The algorithm follows the Modulus 10 Double Add Double approach:
    1. Starting from the rightmost digit, double every second digit
    2. If doubling results in a two-digit number, add the digits together
    3. Sum all the resulting digits
    4. The checksum is (10 - (sum % 10)) % 10

    Args:
        nmi_base: A 10-digit string representing the base NMI

    Returns:
        The calculated checksum digit (0-9)

    Raises:
        ValueError: If nmi_base is not exactly 10 digits or contains non-digits
        TypeError: If nmi_base is None
    """
    if nmi_base is None:
        raise TypeError("NMI base cannot be None")

    if not isinstance(nmi_base, str):
        raise TypeError("NMI base must be a string")

    if len(nmi_base) != 10:
        raise ValueError(f"NMI base must be exactly 10 digits, got {len(nmi_base)}")

    if not nmi_base.isdigit():
        raise ValueError("NMI base must contain only digits")

    total = 0
    # Process from right to left
    for i, digit in enumerate(reversed(nmi_base)):
        num = int(digit)

        # Double every second digit (starting from position 0, which is rightmost)
        if i % 2 == 0:
            num *= 2
            # If result is two digits, add them together
            if num >= 10:
                num = (num // 10) + (num % 10)

        total += num

    # Calculate checksum: (10 - (sum mod 10)) mod 10
    checksum = (10 - (total % 10)) % 10
    return checksum


def validate_nmi_checksum(nmi: str) -> bool:
    """Validate an NMI's checksum digit.

    For 10-digit NMIs: Always returns True (no checksum to validate)
    For 11-digit NMIs: Validates the 11th digit against the calculated checksum

    Args:
        nmi: A 10 or 11 digit NMI string

    Returns:
        True if the NMI is valid, False otherwise
    """
    if nmi is None:
        return False

    if not isinstance(nmi, str):
        return False

    if len(nmi) not in (10, 11):
        return False

    if not nmi.isdigit():
        return False

    # 10-digit NMIs are always valid (no checksum digit present)
    if len(nmi) == 10:
        return True

    # 11-digit NMIs: validate the checksum
    nmi_base = nmi[:10]
    provided_checksum = int(nmi[10])

    try:
        calculated_checksum = calculate_checksum(nmi_base)
        return provided_checksum == calculated_checksum
    except (ValueError, TypeError):
        return False
