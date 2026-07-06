package com.webtransaction.microsite.dto

import com.webtransaction.microsite.domain.ExternalReferenceType
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import com.webtransaction.microsite.domain.WebTransaction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import java.time.LocalDateTime

class WebTransactionResponseTests {

    @Test
    fun `companion factory method creates response from entity`() {
        val now = LocalDateTime.now()
        val entity = WebTransaction(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = mapOf("amount" to 100),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "EXT-001",
            reconcilePayload = mapOf("status" to "completed"),
            reconcileStatus = ReconcileStatus.RECONCILED,
            created = now,
            updated = now
        )

        val response = WebTransactionResponse.from(entity)

        assertEquals(1L, response.id)
        assertEquals("REF-001", response.reference)
        assertEquals(TransactionType.PAYMENT, response.transactionType)
        assertEquals(mapOf("amount" to 100), response.originalPayload)
        assertEquals(ExternalReferenceType.ORDER_ID, response.externalReferenceType)
        assertEquals("EXT-001", response.externalReferenceNumber)
        assertEquals(mapOf("status" to "completed"), response.reconcilePayload)
        assertEquals(ReconcileStatus.RECONCILED, response.reconcileStatus)
        assertEquals(now, response.created)
        assertEquals(now, response.updated)
    }

    @Test
    fun `data class equality works correctly`() {
        val now = LocalDateTime.now()
        val response1 = WebTransactionResponse(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = null,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING,
            created = now,
            updated = now
        )

        val response2 = WebTransactionResponse(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = null,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING,
            created = now,
            updated = now
        )

        assertEquals(response1, response2)
        assertEquals(response1.hashCode(), response2.hashCode())
    }

    @Test
    fun `toString contains field values`() {
        val now = LocalDateTime.now()
        val response = WebTransactionResponse(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = null,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING,
            created = now,
            updated = now
        )

        val toString = response.toString()
        assertTrue(toString.contains("1"))
        assertTrue(toString.contains("REF-001"))
        assertTrue(toString.contains("PAYMENT"))
        assertTrue(toString.contains("PENDING"))
    }
}
