package com.webtransaction.microsite.domain

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class WebTransactionTests {

    @Test
    fun `entity construction sets default values for audit fields`() {
        val transaction = WebTransaction(
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING
        )

        assertNull(transaction.id)
        assertNull(transaction.created)
        assertNull(transaction.updated)
    }

    @Test
    fun `mutable fields can be updated`() {
        val transaction = WebTransaction(
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING
        )

        transaction.externalReferenceNumber = "EXT-001"
        transaction.reconcilePayload = mapOf("status" to "in-progress")
        transaction.reconcileStatus = ReconcileStatus.RECONCILED

        assertEquals("EXT-001", transaction.externalReferenceNumber)
        assertEquals(mapOf("status" to "in-progress"), transaction.reconcilePayload)
        assertEquals(ReconcileStatus.RECONCILED, transaction.reconcileStatus)
    }

    @Test
    fun `data class equality compares by field values`() {
        val transaction1 = WebTransaction(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val transaction2 = WebTransaction(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING
        )

        assertEquals(transaction1, transaction2)

        val transaction3 = transaction1.copy(id = 2L)
        assertNotEquals(transaction1, transaction3)
    }
}
