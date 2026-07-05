#!/usr/bin/env python3
"""Comprehensive test suite for NMI validation."""

import sys
sys.path.insert(0, '.')

from src.nmi_checksum import calculate_checksum, validate_nmi_checksum
from src.nmi_parser import parse_nmi, is_valid_nmi


def run_test_suite(name, tests):
    """Run a suite of test functions."""
    print(f"\n{'=' * 60}")
    print(f"Test Suite: {name}")
    print('=' * 60)

    passed = 0
    failed = 0

    for test_func in tests:
        try:
            test_func()
            passed += 1
            print(f"  ✓ {test_func.__name__}")
        except AssertionError as e:
            failed += 1
            print(f"  ✗ {test_func.__name__}: {e}")
        except Exception as e:
            failed += 1
            print(f"  ✗ {test_func.__name__}: {type(e).__name__}: {e}")

    print(f"\n  Results: {passed} passed, {failed} failed")
    return failed == 0


# Checksum calculation tests
def test_checksum_basic():
    """Test basic checksum calculation."""
    assert 0 <= calculate_checksum("1234567890") <= 9
    assert 0 <= calculate_checksum("0000000000") <= 9
    assert 0 <= calculate_checksum("9999999999") <= 9


def test_checksum_error_empty():
    """Test checksum with empty string."""
    try:
        calculate_checksum("")
        assert False, "Should raise ValueError"
    except ValueError:
        pass


def test_checksum_error_none():
    """Test checksum with None."""
    try:
        calculate_checksum(None)
        assert False, "Should raise TypeError"
    except TypeError:
        pass


def test_checksum_error_non_digits():
    """Test checksum with non-digits."""
    try:
        calculate_checksum("123abc7890")
        assert False, "Should raise ValueError"
    except ValueError:
        pass


def test_checksum_error_wrong_length():
    """Test checksum with wrong length."""
    try:
        calculate_checksum("123")
        assert False, "Should raise ValueError"
    except ValueError:
        pass


# Validation tests
def test_validate_10_digit():
    """Test validation of 10-digit NMIs."""
    assert validate_nmi_checksum("1234567890") is True
    assert validate_nmi_checksum("9876543210") is True
    assert validate_nmi_checksum("0000000000") is True


def test_validate_11_digit_correct():
    """Test validation of 11-digit NMIs with correct checksum."""
    # Generate valid 11-digit NMIs
    base = "1234567890"
    checksum = calculate_checksum(base)
    nmi = base + str(checksum)
    assert validate_nmi_checksum(nmi) is True


def test_validate_11_digit_incorrect():
    """Test validation of 11-digit NMIs with incorrect checksum."""
    base = "1234567890"
    checksum = calculate_checksum(base)
    wrong_checksum = (checksum + 1) % 10
    nmi = base + str(wrong_checksum)
    assert validate_nmi_checksum(nmi) is False


def test_validate_invalid_format():
    """Test validation with invalid formats."""
    assert validate_nmi_checksum("") is False
    assert validate_nmi_checksum(None) is False
    assert validate_nmi_checksum("123abc78901") is False
    assert validate_nmi_checksum("123") is False


# Parser tests
def test_parse_valid_10_digit():
    """Test parsing valid 10-digit NMI."""
    result = parse_nmi("1234567890")
    assert result is not None
    assert result["nmi"] == "1234567890"
    assert result["valid"] is True
    assert result["has_checksum"] is False


def test_parse_valid_11_digit():
    """Test parsing valid 11-digit NMI."""
    result = parse_nmi("12345678903")
    assert result is not None
    assert result["valid"] is True
    assert result["has_checksum"] is True


def test_parse_invalid_11_digit():
    """Test parsing invalid 11-digit NMI."""
    result = parse_nmi("12345678904")
    assert result is not None
    assert result["valid"] is False
    assert result["has_checksum"] is True


def test_parse_invalid_format():
    """Test parsing invalid formats."""
    assert parse_nmi("123") is None
    assert parse_nmi("123abc78901") is None
    assert parse_nmi("") is None
    assert parse_nmi(None) is None


# is_valid_nmi tests
def test_is_valid_10_digit():
    """Test is_valid_nmi with 10-digit NMIs."""
    assert is_valid_nmi("1234567890") is True
    assert is_valid_nmi("0000000000") is True
    assert is_valid_nmi("9999999999") is True


def test_is_valid_11_digit():
    """Test is_valid_nmi with 11-digit NMIs."""
    assert is_valid_nmi("12345678903") is True  # correct checksum
    assert is_valid_nmi("12345678904") is False  # incorrect checksum


def test_is_valid_invalid_format():
    """Test is_valid_nmi with invalid formats."""
    assert is_valid_nmi("123") is False
    assert is_valid_nmi("") is False
    assert is_valid_nmi(None) is False


# Integration tests
def test_integration_end_to_end():
    """Test complete workflow from calculation to validation."""
    # Generate a valid 11-digit NMI
    base = "5555555555"
    checksum = calculate_checksum(base)
    nmi_11 = base + str(checksum)

    # Validate it
    assert validate_nmi_checksum(nmi_11) is True
    assert is_valid_nmi(nmi_11) is True

    # Parse it
    result = parse_nmi(nmi_11)
    assert result is not None
    assert result["valid"] is True
    assert result["has_checksum"] is True


def test_integration_rejection():
    """Test that invalid NMIs are rejected throughout the pipeline."""
    invalid_nmi = "1234567890"
    invalid_nmi += str((calculate_checksum(invalid_nmi) + 1) % 10)

    # Should fail validation
    assert validate_nmi_checksum(invalid_nmi) is False
    assert is_valid_nmi(invalid_nmi) is False

    # Should parse but mark as invalid
    result = parse_nmi(invalid_nmi)
    assert result is not None
    assert result["valid"] is False


def main():
    """Run all test suites."""
    print("\n" + "=" * 60)
    print("NMI VALIDATION - COMPREHENSIVE TEST SUITE")
    print("=" * 60)

    all_passed = True

    # Checksum calculation tests
    checksum_tests = [
        test_checksum_basic,
        test_checksum_error_empty,
        test_checksum_error_none,
        test_checksum_error_non_digits,
        test_checksum_error_wrong_length,
    ]
    all_passed &= run_test_suite("Checksum Calculation", checksum_tests)

    # Validation tests
    validation_tests = [
        test_validate_10_digit,
        test_validate_11_digit_correct,
        test_validate_11_digit_incorrect,
        test_validate_invalid_format,
    ]
    all_passed &= run_test_suite("NMI Checksum Validation", validation_tests)

    # Parser tests
    parser_tests = [
        test_parse_valid_10_digit,
        test_parse_valid_11_digit,
        test_parse_invalid_11_digit,
        test_parse_invalid_format,
    ]
    all_passed &= run_test_suite("NMI Parser", parser_tests)

    # is_valid_nmi tests
    is_valid_tests = [
        test_is_valid_10_digit,
        test_is_valid_11_digit,
        test_is_valid_invalid_format,
    ]
    all_passed &= run_test_suite("is_valid_nmi Function", is_valid_tests)

    # Integration tests
    integration_tests = [
        test_integration_end_to_end,
        test_integration_rejection,
    ]
    all_passed &= run_test_suite("Integration Tests", integration_tests)

    # Final summary
    print("\n" + "=" * 60)
    if all_passed:
        print("✓ ALL TEST SUITES PASSED")
        print("=" * 60 + "\n")
        return 0
    else:
        print("✗ SOME TEST SUITES FAILED")
        print("=" * 60 + "\n")
        return 1


if __name__ == "__main__":
    sys.exit(main())
