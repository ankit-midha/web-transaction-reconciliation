package com.webtransaction.microsite.repository

import com.webtransaction.microsite.domain.ExternalReferenceType
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import com.webtransaction.microsite.domain.WebTransaction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager
import org.springframework.test.context.TestPropertySource

@DataJpaTest
@TestPropertySource(
    properties = [
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect"
    ]
)
class WebTransactionRepositoryTests {

    @Autowired
    private lateinit var repository: WebTransactionRepository

    @Autowired
    private lateinit var entityManager: TestEntityManager

    @Test
    fun `should save and retrieve web transaction by id`() {
        val transaction = WebTransaction(
            reference = "REF-001",
            transactionType = TransactionType.PURCHASE,
            originalPayload = mapOf("key1" to "value1", "key2" to 123),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-123",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val saved = repository.save(transaction)
        entityManager.flush()
        entityManager.clear()

        assertNotNull(saved.id)
        assertNotNull(saved.created)
        assertNotNull(saved.updated)

        val found = repository.findById(saved.id!!).orElse(null)
        assertNotNull(found)
        assertEquals("REF-001", found.reference)
        assertEquals(TransactionType.PURCHASE, found.transactionType)
        assertEquals("ORDER-123", found.externalReferenceNumber)
        assertEquals(ReconcileStatus.PENDING, found.reconcileStatus)
    }

    @Test
    fun `should correctly serialize and deserialize JSONB originalPayload`() {
        val payload = mapOf(
            "orderId" to "12345",
            "amount" to 99.99,
            "items" to listOf(
                mapOf("sku" to "ABC-123", "qty" to 2),
                mapOf("sku" to "XYZ-789", "qty" to 1)
            ),
            "metadata" to mapOf("source" to "web", "campaign" to "summer-sale")
        )

        val transaction = WebTransaction(
            reference = "REF-002",
            transactionType = TransactionType.PURCHASE,
            originalPayload = payload,
            externalReferenceType = ExternalReferenceType.PAYMENT_ID,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val saved = repository.save(transaction)
        entityManager.flush()
        entityManager.clear()

        val found = repository.findById(saved.id!!).orElse(null)
        assertNotNull(found)
        assertNotNull(found.originalPayload)
        assertEquals("12345", found.originalPayload!!["orderId"])
        assertEquals(99.99, found.originalPayload!!["amount"])
        assertTrue(found.originalPayload!!["items"] is List<*>)
        assertTrue(found.originalPayload!!["metadata"] is Map<*, *>)
    }

    @Test
    fun `should correctly serialize and deserialize JSONB reconcilePayload`() {
        val reconcilePayload = mapOf(
            "reconciledAt" to "2026-07-06T10:00:00Z",
            "status" to "success",
            "details" to mapOf("processor" to "stripe", "transactionId" to "ch_123456")
        )

        val transaction = WebTransaction(
            reference = "REF-003",
            transactionType = TransactionType.REFUND,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcilePayload = reconcilePayload,
            reconcileStatus = ReconcileStatus.COMPLETED
        )

        val saved = repository.save(transaction)
        entityManager.flush()
        entityManager.clear()

        val found = repository.findById(saved.id!!).orElse(null)
        assertNotNull(found)
        assertNotNull(found.reconcilePayload)
        assertEquals("2026-07-06T10:00:00Z", found.reconcilePayload!!["reconciledAt"])
        assertEquals("success", found.reconcilePayload!!["status"])
        assertTrue(found.reconcilePayload!!["details"] is Map<*, *>)
    }

    @Test
    fun `should find transaction by reference`() {
        val transaction = WebTransaction(
            reference = "REF-UNIQUE-001",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING
        )

        repository.save(transaction)
        entityManager.flush()
        entityManager.clear()

        val found = repository.findByReference("REF-UNIQUE-001")
        assertNotNull(found)
        assertEquals("REF-UNIQUE-001", found?.reference)
        assertEquals(TransactionType.PURCHASE, found?.transactionType)
    }

    @Test
    fun `should return null when finding by non-existent reference`() {
        val found = repository.findByReference("NON-EXISTENT")
        assertNull(found)
    }

    @Test
    fun `should update transaction fields`() {
        val transaction = WebTransaction(
            reference = "REF-UPDATE-001",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-456",
            reconcileStatus = ReconcileStatus.PENDING
        )

        val saved = repository.save(transaction)
        entityManager.flush()
        entityManager.clear()

        val toUpdate = repository.findById(saved.id!!).orElseThrow()
        toUpdate.externalReferenceNumber = "ORDER-789"
        toUpdate.reconcileStatus = ReconcileStatus.COMPLETED
        toUpdate.reconcilePayload = mapOf("updated" to true)

        repository.save(toUpdate)
        entityManager.flush()
        entityManager.clear()

        val updated = repository.findById(saved.id!!).orElseThrow()
        assertEquals("ORDER-789", updated.externalReferenceNumber)
        assertEquals(ReconcileStatus.COMPLETED, updated.reconcileStatus)
        assertNotNull(updated.reconcilePayload)
        assertEquals(true, updated.reconcilePayload!!["updated"])
    }

    @Test
    fun `should auto-populate created and updated timestamps`() {
        val transaction = WebTransaction(
            reference = "REF-TIMESTAMP-001",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val saved = repository.save(transaction)
        entityManager.flush()

        assertNotNull(saved.created)
        assertNotNull(saved.updated)
        assertEquals(saved.created, saved.updated)
    }

    @Test
    fun `should handle null optional fields`() {
        val transaction = WebTransaction(
            reference = "REF-NULL-001",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            originalPayload = null,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val saved = repository.save(transaction)
        entityManager.flush()
        entityManager.clear()

        val found = repository.findById(saved.id!!).orElseThrow()
        assertNull(found.originalPayload)
        assertNull(found.externalReferenceNumber)
        assertNull(found.reconcilePayload)
    }
}
