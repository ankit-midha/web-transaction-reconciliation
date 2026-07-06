package com.webtransaction.microsite.controller

import com.webtransaction.microsite.exception.EntityNotFoundException
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.core.MethodParameter
import org.springframework.http.HttpStatus
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.security.access.AccessDeniedException
import org.springframework.validation.BeanPropertyBindingResult
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException

class GlobalExceptionHandlerTests {

    private val handler = GlobalExceptionHandler()

    @Test
    fun `handleEntityNotFound returns 404 with error message`() {
        val exception = EntityNotFoundException("Transaction not found")

        val response = handler.handleEntityNotFound(exception)

        assertEquals(HttpStatus.NOT_FOUND, response.statusCode)
        assertEquals("Transaction not found", response.body?.get("error"))
    }

    @Test
    fun `handleValidationErrors returns 400 with field details`() {
        val bindingResult = BeanPropertyBindingResult(Any(), "testObject")
        bindingResult.addError(
            FieldError("testObject", "reference", "Reference is required")
        )
        bindingResult.addError(
            FieldError("testObject", "transactionType", "Transaction type is required")
        )

        val methodParam = object : MethodParameter(
            this::class.java.getMethod("toString"),
            -1
        ) {}
        val exception = MethodArgumentNotValidException(methodParam, bindingResult)

        val response = handler.handleValidationErrors(exception)

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("Validation failed", response.body?.get("error"))
        val details = response.body?.get("details") as? Map<*, *>
        assertEquals("Reference is required", details?.get("reference"))
        assertEquals("Transaction type is required", details?.get("transactionType"))
    }

    @Test
    fun `handleHttpMessageNotReadable returns 400 for enum error`() {
        val exception = HttpMessageNotReadableException(
            "JSON parse error: Cannot deserialize value of type INVALID_ENUM " +
                "not one of the values accepted for Enum class: [PAYMENT, REFUND]",
            null as org.springframework.http.HttpInputMessage?
        )

        val response = handler.handleHttpMessageNotReadable(exception)

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("Invalid enum value provided", response.body?.get("error"))
    }

    @Test
    fun `handleHttpMessageNotReadable returns 400 for malformed JSON`() {
        val exception = HttpMessageNotReadableException(
            "JSON parse error: Unexpected character",
            null as org.springframework.http.HttpInputMessage?
        )

        val response = handler.handleHttpMessageNotReadable(exception)

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("Malformed JSON request", response.body?.get("error"))
    }

    @Test
    fun `handleAccessDenied returns 403`() {
        val exception = AccessDeniedException("Access is denied")

        val response = handler.handleAccessDenied(exception)

        assertEquals(HttpStatus.FORBIDDEN, response.statusCode)
        assertEquals("Access denied", response.body?.get("error"))
    }

    @Test
    fun `handleGenericException returns 500`() {
        val exception = RuntimeException("Unexpected error")

        val response = handler.handleGenericException(exception)

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.statusCode)
        assertEquals("Internal server error", response.body?.get("error"))
    }
}
