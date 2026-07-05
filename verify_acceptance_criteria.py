#!/usr/bin/env python3
"""Verify that the implementation meets all acceptance criteria."""

import sys
sys.path.insert(0, '.')

from src.nmi_parser import is_valid_nmi


def verify_acceptance_criteria():
    """Verify each acceptance criterion from the spec."""
    print("=" * 60)
    print("ACCEPTANCE CRITERIA VERIFICATION")
    print("=" * 60 + "\n")

    all_passed = True

    # Criterion 1: Valid 10-digit NMIs continue to pass validation
    print("1. Valid 10-digit NMIs continue to pass validation")
    test_cases = ["1234567890", "9876543210", "0000000000", "9999999999"]
    for nmi in test_cases:
        result = is_valid_nmi(nmi)
        status = "✓" if result else "✗"
        print(f"   {status} is_valid_nmi('{nmi}') = {result}")
        if not result:
            all_passed = False
    print()

    # Criterion 2: Invalid checksums return false (no exception thrown)
    print("2. Invalid checksums return false (no exception thrown)")
    invalid_cases = [
        "12345678904",  # wrong checksum (should be 3)
        "98765432104",  # wrong checksum (should be 3)
    ]
    for nmi in invalid_cases:
        try:
            result = is_valid_nmi(nmi)
            if result is False:
                print(f"   ✓ is_valid_nmi('{nmi}') = False (no exception)")
            else:
                print(f"   ✗ is_valid_nmi('{nmi}') = {result} (expected False)")
                all_passed = False
        except Exception as e:
            print(f"   ✗ is_valid_nmi('{nmi}') raised {type(e).__name__}: {e}")
            all_passed = False
    print()

    # Criterion 3: 11-digit NMIs (with checksum suffix) validate against the suffix digit
    print("3. 11-digit NMIs (with checksum suffix) validate against suffix")
    valid_11_digit = [
        "12345678903",  # checksum = 3 (valid)
        "98765432103",  # checksum = 3 (valid)
        "00000000000",  # checksum = 0 (valid)
        "99999999990",  # checksum = 0 (valid)
    ]
    for nmi in valid_11_digit:
        result = is_valid_nmi(nmi)
        status = "✓" if result else "✗"
        print(f"   {status} is_valid_nmi('{nmi}') = {result}")
        if not result:
            all_passed = False

    invalid_11_digit = [
        "12345678904",  # checksum should be 3, not 4
        "98765432104",  # checksum should be 3, not 4
        "00000000001",  # checksum should be 0, not 1
        "99999999991",  # checksum should be 0, not 1
    ]
    for nmi in invalid_11_digit:
        result = is_valid_nmi(nmi)
        status = "✓" if not result else "✗"
        print(f"   {status} is_valid_nmi('{nmi}') = {result} (expected False)")
        if result:
            all_passed = False
    print()

    # Summary
    print("=" * 60)
    if all_passed:
        print("✓ ALL ACCEPTANCE CRITERIA MET")
    else:
        print("✗ SOME ACCEPTANCE CRITERIA NOT MET")
    print("=" * 60 + "\n")

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(verify_acceptance_criteria())
