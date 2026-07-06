package com.webtransaction.microsite.service

import com.ninjasquad.springmockk.MockkBean
import com.webtransaction.microsite.domain.ExternalReferenceType
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import com.webtransaction.microsite.domain.WebTransaction
import com.webtransaction.microsite.exception.EntityNotFoundException
import com.webtransaction.microsite.repository.WebTransactionRepository
import io.mockk.every
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.TestPropertySource
import java.time.LocalDateTime
import java.util.Optional

@SpringBootTest
@TestPropertySource(properties = ["spring.jpa.hibernate.ddl-auto=none"])
class WebTransactionServiceTests {

    @Autowired
    private lateinit var service: WebTransactionService

    @MockkBean
    private lateinit var repository: WebTransactionRepository

    @Test
    fun `create should save transaction and return saved entity`() {
        val slot = slot<WebTransaction>()
        val savedTransaction = WebTransaction(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PURCHASE,
            originalPayload = mapOf("key" to "value"),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-123",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every { repository.save(capture(slot)) } returns savedTransaction

        val result = service.create(
            reference = "REF-001",
            transactionType = TransactionType.PURCHASE,
            originalPayload = mapOf("key" to "value"),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-123",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        assertNotNull(result)
        assertEquals(1L, result.id)
        assertEquals("REF-001", result.reference)
        assertEquals(TransactionType.PURCHASE, result.transactionType)
        verify(exactly = 1) { repository.save(any()) }
        assertEquals("REF-001", slot.captured.reference)
    }

    @Test
    fun `getById should return transaction when found`() {
        val transaction = WebTransaction(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every { repository.findById(1L) } returns Optional.of(transaction)

        val result = service.getById(1L)

        assertNotNull(result)
        assertEquals(1L, result.id)
        assertEquals("REF-001", result.reference)
        verify(exactly = 1) { repository.findById(1L) }
    }

    @Test
    fun `getById should throw EntityNotFoundException when not found`() {
        every { repository.findById(999L) } returns Optional.empty()

        val exception = assertThrows(EntityNotFoundException::class.java) {
            service.getById(999L)
        }

        assertEquals("Web transaction not found with id: 999", exception.message)
        verify(exactly = 1) { repository.findById(999L) }
    }

    @Test
    fun `getByReference should return transaction when found`() {
        val transaction = WebTransaction(
            id = 1L,
            reference = "REF-FOUND",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every { repository.findByReference("REF-FOUND") } returns transaction

        val result = service.getByReference("REF-FOUND")

        assertNotNull(result)
        assertEquals("REF-FOUND", result.reference)
        verify(exactly = 1) { repository.findByReference("REF-FOUND") }
    }

    @Test
    fun `getByReference should throw EntityNotFoundException when not found`() {
        every { repository.findByReference("REF-NOT-FOUND") } returns null

        val exception = assertThrows(EntityNotFoundException::class.java) {
            service.getByReference("REF-NOT-FOUND")
        }

        assertEquals("Web transaction not found with reference: REF-NOT-FOUND", exception.message)
        verify(exactly = 1) { repository.findByReference("REF-NOT-FOUND") }
    }

    @Test
    fun `updateByReference should update only reconcile fields when found`() {
        val existingTransaction = WebTransaction(
            id = 1L,
            reference = "REF-UPDATE",
            transactionType = TransactionType.PURCHASE,
            originalPayload = mapOf("original" to "data"),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-OLD",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now().minusDays(1),
            updated = LocalDateTime.now().minusDays(1)
        )

        val slot = slot<WebTransaction>()
        every { repository.findByReference("REF-UPDATE") } returns existingTransaction
        every { repository.save(capture(slot)) } answers { slot.captured }

        val result = service.updateByReference(
            reference = "REF-UPDATE",
            reconcileStatus = ReconcileStatus.COMPLETED,
            externalReferenceNumber = "ORDER-NEW",
            reconcilePayload = mapOf("reconciled" to true)
        )

        assertNotNull(result)
        assertEquals(ReconcileStatus.COMPLETED, result.reconcileStatus)
        assertEquals("ORDER-NEW", result.externalReferenceNumber)
        assertEquals(mapOf("reconciled" to true), result.reconcilePayload)
        assertEquals("REF-UPDATE", result.reference)
        assertEquals(TransactionType.PURCHASE, result.transactionType)
        assertEquals(mapOf("original" to "data"), result.originalPayload)
        verify(exactly = 1) { repository.findByReference("REF-UPDATE") }
        verify(exactly = 1) { repository.save(any()) }
    }

    @Test
    fun `updateByReference should update only provided fields`() {
        val existingTransaction = WebTransaction(
            id = 1L,
            reference = "REF-PARTIAL",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-123",
            reconcilePayload = mapOf("old" to "payload"),
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every { repository.findByReference("REF-PARTIAL") } returns existingTransaction
        every { repository.save(any()) } answers { firstArg() }

        val result = service.updateByReference(
            reference = "REF-PARTIAL",
            reconcileStatus = ReconcileStatus.COMPLETED,
            externalReferenceNumber = null,
            reconcilePayload = null
        )

        assertEquals(ReconcileStatus.COMPLETED, result.reconcileStatus)
        assertEquals("ORDER-123", result.externalReferenceNumber)
        assertEquals(mapOf("old" to "payload"), result.reconcilePayload)
    }

    @Test
    fun `updateByReference should throw EntityNotFoundException when reference not found`() {
        every { repository.findByReference("REF-MISSING") } returns null

        val exception = assertThrows(EntityNotFoundException::class.java) {
            service.updateByReference(
                reference = "REF-MISSING",
                reconcileStatus = ReconcileStatus.COMPLETED,
                externalReferenceNumber = null,
                reconcilePayload = null
            )
        }

        assertEquals("Web transaction not found with reference: REF-MISSING", exception.message)
        verify(exactly = 1) { repository.findByReference("REF-MISSING") }
        verify(exactly = 0) { repository.save(any()) }
    }

    @Test
    fun `create should handle null optional fields`() {
        val slot = slot<WebTransaction>()
        val savedTransaction = WebTransaction(
            id = 2L,
            reference = "REF-NULL",
            transactionType = TransactionType.REFUND,
            originalPayload = null,
            externalReferenceType = ExternalReferenceType.PAYMENT_ID,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every { repository.save(capture(slot)) } returns savedTransaction

        val result = service.create(
            reference = "REF-NULL",
            transactionType = TransactionType.REFUND,
            originalPayload = null,
            externalReferenceType = ExternalReferenceType.PAYMENT_ID,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        assertNotNull(result)
        assertEquals("REF-NULL", result.reference)
        verify(exactly = 1) { repository.save(any()) }
    }
}
