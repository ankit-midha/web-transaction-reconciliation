package com.webtransaction.microsite.dto

import com.webtransaction.microsite.domain.ReconcileStatus
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class UpdateWebTransactionRequestTests {

    @Test
    fun `data class equality works correctly`() {
        val request1 = UpdateWebTransactionRequest(
            reconcileStatus = ReconcileStatus.RECONCILED,
            externalReferenceNumber = "EXT-002",
            reconcilePayload = mapOf("status" to "completed")
        )

        val request2 = UpdateWebTransactionRequest(
            reconcileStatus = ReconcileStatus.RECONCILED,
            externalReferenceNumber = "EXT-002",
            reconcilePayload = mapOf("status" to "completed")
        )

        assertEquals(request1, request2)
        assertEquals(request1.hashCode(), request2.hashCode())
    }

    @Test
    fun `all fields default to null`() {
        val request = UpdateWebTransactionRequest()

        assertNull(request.reconcileStatus)
        assertNull(request.externalReferenceNumber)
        assertNull(request.reconcilePayload)
    }

    @Test
    fun `data class copy works with partial fields`() {
        val original = UpdateWebTransactionRequest(
            reconcileStatus = ReconcileStatus.PENDING,
            externalReferenceNumber = null,
            reconcilePayload = null
        )

        val copied = original.copy(reconcileStatus = ReconcileStatus.RECONCILED)

        assertEquals(ReconcileStatus.RECONCILED, copied.reconcileStatus)
        assertNull(copied.externalReferenceNumber)
        assertNull(copied.reconcilePayload)
    }

    @Test
    fun `toString contains field values`() {
        val request = UpdateWebTransactionRequest(
            reconcileStatus = ReconcileStatus.RECONCILED,
            externalReferenceNumber = "EXT-002",
            reconcilePayload = mapOf("status" to "completed")
        )

        val toString = request.toString()
        assertTrue(toString.contains("RECONCILED"))
        assertTrue(toString.contains("EXT-002"))
    }
}
