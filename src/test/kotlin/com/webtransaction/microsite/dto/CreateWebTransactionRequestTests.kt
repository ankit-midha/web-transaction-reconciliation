package com.webtransaction.microsite.dto

import com.webtransaction.microsite.domain.ExternalReferenceType
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class CreateWebTransactionRequestTests {

    @Test
    fun `data class equality works correctly`() {
        val request1 = CreateWebTransactionRequest(
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = mapOf("amount" to 100),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "EXT-001",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val request2 = CreateWebTransactionRequest(
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = mapOf("amount" to 100),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "EXT-001",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        assertEquals(request1, request2)
        assertEquals(request1.hashCode(), request2.hashCode())
    }

    @Test
    fun `data class copy works with all fields`() {
        val original = CreateWebTransactionRequest(
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = mapOf("amount" to 100),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "EXT-001",
            reconcilePayload = mapOf("status" to "pending"),
            reconcileStatus = ReconcileStatus.PENDING
        )

        val copied = original.copy(
            reference = "REF-002",
            transactionType = TransactionType.REFUND,
            originalPayload = mapOf("amount" to 200),
            externalReferenceType = ExternalReferenceType.PAYMENT_ID,
            externalReferenceNumber = "EXT-002",
            reconcilePayload = mapOf("status" to "completed"),
            reconcileStatus = ReconcileStatus.RECONCILED
        )

        assertEquals("REF-002", copied.reference)
        assertEquals(TransactionType.REFUND, copied.transactionType)
        assertEquals(mapOf("amount" to 200), copied.originalPayload)
        assertEquals(ExternalReferenceType.PAYMENT_ID, copied.externalReferenceType)
        assertEquals("EXT-002", copied.externalReferenceNumber)
        assertEquals(mapOf("status" to "completed"), copied.reconcilePayload)
        assertEquals(ReconcileStatus.RECONCILED, copied.reconcileStatus)
    }

    @Test
    fun `toString contains field values`() {
        val request = CreateWebTransactionRequest(
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = null,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val toString = request.toString()
        assertTrue(toString.contains("REF-001"))
        assertTrue(toString.contains("PAYMENT"))
        assertTrue(toString.contains("ORDER_ID"))
        assertTrue(toString.contains("PENDING"))
    }
}
