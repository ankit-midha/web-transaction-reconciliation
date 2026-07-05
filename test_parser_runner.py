#!/usr/bin/env python3
"""Manual test runner for NMI parser."""

import sys
sys.path.insert(0, '.')

from src.nmi_parser import parse_nmi, is_valid_nmi


def test_parse_nmi():
    """Test parse_nmi function."""
    print("Testing parse_nmi...")

    # Valid 10-digit
    result = parse_nmi("1234567890")
    print(f"  parse_nmi('1234567890') = {result}")
    assert result is not None
    assert result["nmi"] == "1234567890"
    assert result["valid"] is True
    assert result["has_checksum"] is False
    print("    ✓ Valid 10-digit NMI")

    # Valid 11-digit with correct checksum
    result = parse_nmi("12345678903")
    print(f"  parse_nmi('12345678903') = {result}")
    assert result is not None
    assert result["nmi"] == "12345678903"
    assert result["valid"] is True
    assert result["has_checksum"] is True
    print("    ✓ Valid 11-digit NMI with correct checksum")

    # Invalid 11-digit with wrong checksum
    result = parse_nmi("12345678904")
    print(f"  parse_nmi('12345678904') = {result}")
    assert result is not None
    assert result["nmi"] == "12345678904"
    assert result["valid"] is False
    assert result["has_checksum"] is True
    print("    ✓ Invalid 11-digit NMI with wrong checksum")

    # Invalid format cases
    assert parse_nmi("123") is None
    print("    ✓ Wrong length returns None")

    assert parse_nmi("123abc78901") is None
    print("    ✓ Non-digits return None")

    assert parse_nmi("") is None
    print("    ✓ Empty string returns None")

    assert parse_nmi(None) is None
    print("    ✓ None returns None")

    print("  ✓ All parse_nmi tests passed\n")


def test_is_valid_nmi():
    """Test is_valid_nmi function."""
    print("Testing is_valid_nmi...")

    # Valid cases
    assert is_valid_nmi("1234567890") is True
    print("  is_valid_nmi('1234567890') = True ✓")

    assert is_valid_nmi("12345678903") is True
    print("  is_valid_nmi('12345678903') = True ✓")

    assert is_valid_nmi("00000000000") is True
    print("  is_valid_nmi('00000000000') = True ✓")

    assert is_valid_nmi("99999999990") is True
    print("  is_valid_nmi('99999999990') = True ✓")

    # Invalid cases
    assert is_valid_nmi("12345678904") is False
    print("  is_valid_nmi('12345678904') = False ✓")

    assert is_valid_nmi("123") is False
    print("  is_valid_nmi('123') = False ✓")

    assert is_valid_nmi("123456789012") is False
    print("  is_valid_nmi('123456789012') = False ✓")

    assert is_valid_nmi("123abc78901") is False
    print("  is_valid_nmi('123abc78901') = False ✓")

    assert is_valid_nmi("") is False
    print("  is_valid_nmi('') = False ✓")

    assert is_valid_nmi(None) is False
    print("  is_valid_nmi(None) = False ✓")

    print("  ✓ All is_valid_nmi tests passed\n")


def main():
    """Run all tests."""
    print("=" * 60)
    print("NMI Parser Tests")
    print("=" * 60 + "\n")

    try:
        test_parse_nmi()
        test_is_valid_nmi()
        print("=" * 60)
        print("✓ ALL TESTS PASSED")
        print("=" * 60)
        return 0
    except AssertionError as e:
        print(f"\n✗ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        return 1
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
