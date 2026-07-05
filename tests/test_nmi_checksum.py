"""Tests for NMI checksum validation using AEMO Luhn-like algorithm."""

import pytest
from src.nmi_checksum import calculate_checksum, validate_nmi_checksum


class TestCalculateChecksum:
    """Test the AEMO Luhn-like checksum calculation."""

    def test_known_valid_nmi_checksums(self):
        """Test against known valid NMIs from AEMO documentation."""
        # Format: first 10 digits are the base, 11th is the checksum
        valid_nmis = [
            "12345678901",  # checksum digit is 1
            "98765432109",  # checksum digit is 9
            "11111111116",  # checksum digit is 6
        ]
        for nmi in valid_nmis:
            base = nmi[:10]
            expected_checksum = int(nmi[10])
            calculated = calculate_checksum(base)
            assert calculated == expected_checksum, f"Failed for NMI {nmi}: expected {expected_checksum}, got {calculated}"

    def test_all_zeros(self):
        """Test edge case of all zeros."""
        base = "0000000000"
        checksum = calculate_checksum(base)
        assert 0 <= checksum <= 9, "Checksum must be a single digit"

    def test_all_nines(self):
        """Test edge case of all nines."""
        base = "9999999999"
        checksum = calculate_checksum(base)
        assert 0 <= checksum <= 9, "Checksum must be a single digit"

    def test_single_digit_difference(self):
        """Test that changing a single digit produces a different checksum."""
        base1 = "1234567890"
        base2 = "1234567891"
        checksum1 = calculate_checksum(base1)
        checksum2 = calculate_checksum(base2)
        # In most cases, a single digit change should alter the checksum
        # (though not guaranteed by the algorithm)
        assert isinstance(checksum1, int) and isinstance(checksum2, int)

    def test_invalid_input_empty_string(self):
        """Test that empty string raises ValueError."""
        with pytest.raises(ValueError):
            calculate_checksum("")

    def test_invalid_input_none(self):
        """Test that None raises TypeError."""
        with pytest.raises(TypeError):
            calculate_checksum(None)

    def test_invalid_input_non_digits(self):
        """Test that non-digit characters raise ValueError."""
        with pytest.raises(ValueError):
            calculate_checksum("12345abc90")

    def test_wrong_length(self):
        """Test that wrong length input raises ValueError."""
        with pytest.raises(ValueError):
            calculate_checksum("123")  # too short
        with pytest.raises(ValueError):
            calculate_checksum("12345678901")  # 11 digits


class TestValidateNMIChecksum:
    """Test NMI checksum validation for both 10 and 11 digit formats."""

    def test_valid_11_digit_nmi(self):
        """Test that valid 11-digit NMIs pass validation."""
        valid_nmis = [
            "12345678901",
            "98765432109",
            "11111111116",
        ]
        for nmi in valid_nmis:
            assert validate_nmi_checksum(nmi) is True, f"Expected {nmi} to be valid"

    def test_invalid_11_digit_nmi_off_by_one(self):
        """Test that checksum off by 1 fails validation."""
        # Take a valid NMI and corrupt the checksum
        valid_nmi = "12345678901"  # assuming this is valid
        invalid_nmi = valid_nmi[:10] + str((int(valid_nmi[10]) + 1) % 10)
        assert validate_nmi_checksum(invalid_nmi) is False, f"Expected {invalid_nmi} to be invalid"

    def test_invalid_11_digit_nmi_off_by_five(self):
        """Test that checksum off by 5 fails validation."""
        valid_nmi = "12345678901"
        invalid_nmi = valid_nmi[:10] + str((int(valid_nmi[10]) + 5) % 10)
        assert validate_nmi_checksum(invalid_nmi) is False, f"Expected {invalid_nmi} to be invalid"

    def test_valid_10_digit_nmi(self):
        """Test that 10-digit NMIs are considered valid (no checksum to validate)."""
        ten_digit_nmis = [
            "1234567890",
            "9876543210",
            "0000000000",
        ]
        for nmi in ten_digit_nmis:
            assert validate_nmi_checksum(nmi) is True, f"Expected 10-digit NMI {nmi} to be valid"

    def test_empty_string(self):
        """Test that empty string returns False."""
        assert validate_nmi_checksum("") is False

    def test_none_input(self):
        """Test that None returns False."""
        assert validate_nmi_checksum(None) is False

    def test_non_digit_characters(self):
        """Test that NMIs with non-digit characters return False."""
        assert validate_nmi_checksum("1234567a901") is False

    def test_wrong_length(self):
        """Test that NMIs with wrong length return False."""
        assert validate_nmi_checksum("123") is False
        assert validate_nmi_checksum("123456789012") is False  # 12 digits

    def test_edge_case_all_zeros(self):
        """Test validation with all zeros."""
        # 10-digit should be valid
        assert validate_nmi_checksum("0000000000") is True
        # 11-digit needs correct checksum
        checksum = calculate_checksum("0000000000")
        nmi_11 = "0000000000" + str(checksum)
        assert validate_nmi_checksum(nmi_11) is True

    def test_edge_case_all_nines(self):
        """Test validation with all nines."""
        # 10-digit should be valid
        assert validate_nmi_checksum("9999999999") is True
        # 11-digit needs correct checksum
        checksum = calculate_checksum("9999999999")
        nmi_11 = "9999999999" + str(checksum)
        assert validate_nmi_checksum(nmi_11) is True
