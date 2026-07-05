#!/usr/bin/env python3
"""Manual test runner for NMI checksum validation."""

import sys
sys.path.insert(0, '.')

from src.nmi_checksum import calculate_checksum, validate_nmi_checksum


def test_calculate_checksum():
    """Test checksum calculation."""
    print("Testing calculate_checksum...")

    # Test known valid NMIs
    test_cases = [
        ("1234567890", None),  # We'll calculate and verify it's 0-9
        ("0000000000", None),
        ("9999999999", None),
    ]

    for base, expected in test_cases:
        result = calculate_checksum(base)
        print(f"  calculate_checksum('{base}') = {result}")
        assert 0 <= result <= 9, f"Checksum must be 0-9, got {result}"

    # Test error handling
    print("  Testing error cases...")
    try:
        calculate_checksum("")
        assert False, "Should raise ValueError for empty string"
    except ValueError:
        print("    Empty string raises ValueError ✓")

    try:
        calculate_checksum(None)
        assert False, "Should raise TypeError for None"
    except TypeError:
        print("    None raises TypeError ✓")

    try:
        calculate_checksum("123abc7890")
        assert False, "Should raise ValueError for non-digits"
    except ValueError:
        print("    Non-digits raise ValueError ✓")

    try:
        calculate_checksum("123")
        assert False, "Should raise ValueError for wrong length"
    except ValueError:
        print("    Wrong length raises ValueError ✓")

    print("  ✓ All calculate_checksum tests passed\n")


def test_validate_nmi_checksum():
    """Test NMI validation."""
    print("Testing validate_nmi_checksum...")

    # Generate valid 11-digit NMIs by calculating checksums
    test_10_digit = ["1234567890", "9876543210", "0000000000", "9999999999"]

    for base in test_10_digit:
        # Test 10-digit (should always be valid)
        result = validate_nmi_checksum(base)
        print(f"  validate_nmi_checksum('{base}') = {result}")
        assert result is True, f"10-digit NMI should be valid"

        # Test 11-digit with correct checksum
        checksum = calculate_checksum(base)
        nmi_11 = base + str(checksum)
        result = validate_nmi_checksum(nmi_11)
        print(f"  validate_nmi_checksum('{nmi_11}') = {result}")
        assert result is True, f"11-digit NMI with correct checksum should be valid"

        # Test 11-digit with incorrect checksum
        wrong_checksum = (checksum + 1) % 10
        nmi_11_wrong = base + str(wrong_checksum)
        result = validate_nmi_checksum(nmi_11_wrong)
        print(f"  validate_nmi_checksum('{nmi_11_wrong}') = {result}")
        assert result is False, f"11-digit NMI with wrong checksum should be invalid"

    # Test error cases
    print("  Testing error cases...")
    assert validate_nmi_checksum("") is False, "Empty string should be invalid"
    print("    Empty string returns False ✓")

    assert validate_nmi_checksum(None) is False, "None should be invalid"
    print("    None returns False ✓")

    assert validate_nmi_checksum("123abc78901") is False, "Non-digits should be invalid"
    print("    Non-digits return False ✓")

    assert validate_nmi_checksum("123") is False, "Wrong length should be invalid"
    print("    Wrong length returns False ✓")

    print("  ✓ All validate_nmi_checksum tests passed\n")


def main():
    """Run all tests."""
    print("=" * 60)
    print("NMI Checksum Validation Tests")
    print("=" * 60 + "\n")

    try:
        test_calculate_checksum()
        test_validate_nmi_checksum()
        print("=" * 60)
        print("✓ ALL TESTS PASSED")
        print("=" * 60)
        return 0
    except AssertionError as e:
        print(f"\n✗ TEST FAILED: {e}")
        return 1
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
