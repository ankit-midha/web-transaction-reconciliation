"""Tests for NMI parser with integrated checksum validation."""

import pytest
from src.nmi_parser import parse_nmi, is_valid_nmi


class TestParseNMI:
    """Test the NMI parser function."""

    def test_parse_valid_10_digit_nmi(self):
        """Test parsing a valid 10-digit NMI."""
        result = parse_nmi("1234567890")
        assert result is not None
        assert result["nmi"] == "1234567890"
        assert result["valid"] is True
        assert result["has_checksum"] is False

    def test_parse_valid_11_digit_nmi(self):
        """Test parsing a valid 11-digit NMI with correct checksum."""
        result = parse_nmi("12345678903")  # checksum calculated in previous test
        assert result is not None
        assert result["nmi"] == "12345678903"
        assert result["valid"] is True
        assert result["has_checksum"] is True

    def test_parse_invalid_11_digit_nmi(self):
        """Test parsing an 11-digit NMI with incorrect checksum."""
        result = parse_nmi("12345678904")  # wrong checksum
        assert result is not None
        assert result["nmi"] == "12345678904"
        assert result["valid"] is False
        assert result["has_checksum"] is True

    def test_parse_invalid_length(self):
        """Test parsing NMI with invalid length."""
        result = parse_nmi("123")
        assert result is None

    def test_parse_non_digits(self):
        """Test parsing NMI with non-digit characters."""
        result = parse_nmi("123abc78901")
        assert result is None

    def test_parse_empty_string(self):
        """Test parsing empty string."""
        result = parse_nmi("")
        assert result is None

    def test_parse_none(self):
        """Test parsing None."""
        result = parse_nmi(None)
        assert result is None


class TestIsValidNMI:
    """Test the simplified validation function."""

    def test_valid_10_digit_nmi(self):
        """Test that valid 10-digit NMIs return True."""
        assert is_valid_nmi("1234567890") is True
        assert is_valid_nmi("9876543210") is True
        assert is_valid_nmi("0000000000") is True

    def test_valid_11_digit_nmi(self):
        """Test that valid 11-digit NMIs with correct checksum return True."""
        assert is_valid_nmi("12345678903") is True
        assert is_valid_nmi("98765432103") is True
        assert is_valid_nmi("00000000000") is True

    def test_invalid_11_digit_nmi(self):
        """Test that 11-digit NMIs with incorrect checksum return False."""
        assert is_valid_nmi("12345678904") is False  # wrong checksum
        assert is_valid_nmi("98765432104") is False  # wrong checksum

    def test_invalid_format(self):
        """Test that invalid formats return False."""
        assert is_valid_nmi("123") is False  # too short
        assert is_valid_nmi("123456789012") is False  # too long
        assert is_valid_nmi("123abc78901") is False  # non-digits
        assert is_valid_nmi("") is False  # empty
        assert is_valid_nmi(None) is False  # None

    def test_edge_cases(self):
        """Test edge cases."""
        # All zeros
        assert is_valid_nmi("0000000000") is True  # 10-digit
        assert is_valid_nmi("00000000000") is True  # 11-digit with correct checksum

        # All nines
        assert is_valid_nmi("9999999999") is True  # 10-digit
        assert is_valid_nmi("99999999990") is True  # 11-digit with correct checksum
