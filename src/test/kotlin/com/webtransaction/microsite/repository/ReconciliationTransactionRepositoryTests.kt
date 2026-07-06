package com.webtransaction.microsite.repository

import com.webtransaction.microsite.entity.ExternalReferenceType
import com.webtransaction.microsite.entity.ReconcileStatus
import com.webtransaction.microsite.entity.ReconciliationTransaction
import com.webtransaction.microsite.entity.TransactionType
import jakarta.persistence.EntityManager
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.orm.ObjectOptimisticLockingFailureException
import org.springframework.test.context.jdbc.Sql
import java.math.BigDecimal
import java.time.LocalDateTime
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class ReconciliationTransactionRepositoryTests {

    @Autowired
    private lateinit var repository: ReconciliationTransactionRepository

    @Autowired
    private lateinit var entityManager: EntityManager

    @Autowired
    private lateinit var jdbcTemplate: JdbcTemplate

    @Test
    fun `Flyway migrations applied successfully`() {
        val versions = jdbcTemplate.query(
            "SELECT version FROM flyway_schema_history ORDER BY installed_rank",
        ) { rs, _ -> rs.getString("version") }

        assertEquals(4, versions.size)
        assertEquals("1", versions[0])
        assertEquals("2", versions[1])
        assertEquals("3", versions[2])
        assertEquals("4", versions[3])
    }

    @Test
    fun `reconciliation_transaction table exists with correct schema`() {
        val columns = jdbcTemplate.query(
            """
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'reconciliation_transaction'
            ORDER BY ordinal_position
            """.trimIndent(),
        ) { rs, _ ->
            Triple(
                rs.getString("column_name"),
                rs.getString("data_type"),
                rs.getString("is_nullable"),
            )
        }

        assertTrue(columns.isNotEmpty())
        assertTrue(columns.any { it.first == "id" })
        assertTrue(columns.any { it.first == "reference" })
        assertTrue(columns.any { it.first == "transaction_type" })
        assertTrue(columns.any { it.first == "external_reference_type" })
        assertTrue(columns.any { it.first == "external_reference" })
        assertTrue(columns.any { it.first == "amount" })
        assertTrue(columns.any { it.first == "status" })
        assertTrue(columns.any { it.first == "created" })
        assertTrue(columns.any { it.first == "updated" })
        assertTrue(columns.any { it.first == "version" })
    }

    @Test
    fun `save creates a new ReconciliationTransaction`() {
        val transaction = ReconciliationTransaction(
            reference = "TEST-REF-001",
            transactionType = TransactionType.WEB_ELECTRICITY_ORDER,
            externalReferenceType = ExternalReferenceType.SAP,
            externalReference = "SAP-001",
            amount = BigDecimal("99.99"),
            status = ReconcileStatus.PENDING,
        )

        val saved = repository.save(transaction)

        assertNotNull(saved.id)
        assertEquals("TEST-REF-001", saved.reference)
        assertEquals(TransactionType.WEB_ELECTRICITY_ORDER, saved.transactionType)
        assertEquals(ExternalReferenceType.SAP, saved.externalReferenceType)
        assertEquals("SAP-001", saved.externalReference)
        assertEquals(BigDecimal("99.99"), saved.amount)
        assertEquals(ReconcileStatus.PENDING, saved.status)
        assertNotNull(saved.created)
        assertNotNull(saved.updated)
        assertEquals(0L, saved.version)
    }

    @Test
    fun `findByReference returns correct entity`() {
        val transaction = ReconciliationTransaction(
            reference = "FIND-BY-REF-001",
            transactionType = TransactionType.WEB_GAS_ORDER,
            externalReferenceType = ExternalReferenceType.SALESFORCE,
            externalReference = "SF-001",
            amount = BigDecimal("50.00"),
            status = ReconcileStatus.MATCHED,
        )

        repository.save(transaction)
        entityManager.flush()
        entityManager.clear()

        val found = repository.findByReference("FIND-BY-REF-001")

        assertNotNull(found)
        assertEquals("FIND-BY-REF-001", found.reference)
        assertEquals(TransactionType.WEB_GAS_ORDER, found.transactionType)
        assertEquals(ExternalReferenceType.SALESFORCE, found.externalReferenceType)
        assertEquals("SF-001", found.externalReference)
        assertEquals(BigDecimal("50.00"), found.amount)
        assertEquals(ReconcileStatus.MATCHED, found.status)
    }

    @Test
    fun `findByReference returns null for nonexistent reference`() {
        val found = repository.findByReference("NONEXISTENT-REF")
        assertNull(found)
    }

    @Test
    fun `update increments version number`() {
        val transaction = ReconciliationTransaction(
            reference = "VERSION-TEST-001",
            transactionType = TransactionType.WEB_BROADBAND_ORDER,
            externalReferenceType = ExternalReferenceType.ZENDESK,
            amount = BigDecimal("100.00"),
            status = ReconcileStatus.PENDING,
        )

        val saved = repository.save(transaction)
        val originalVersion = saved.version
        entityManager.flush()
        entityManager.clear()

        val loaded = repository.findById(saved.id!!).get()
        loaded.status = ReconcileStatus.MATCHED
        val updated = repository.save(loaded)
        entityManager.flush()

        assertEquals(originalVersion + 1, updated.version)
        assertEquals(ReconcileStatus.MATCHED, updated.status)
    }

    @Test
    fun `optimistic locking throws exception on concurrent update`() {
        val transaction = ReconciliationTransaction(
            reference = "CONCURRENT-TEST-001",
            transactionType = TransactionType.WEB_ELECTRICITY_ORDER,
            externalReferenceType = ExternalReferenceType.SAP,
            amount = BigDecimal("75.00"),
            status = ReconcileStatus.PENDING,
        )

        val saved = repository.save(transaction)
        entityManager.flush()
        entityManager.clear()

        val instance1 = repository.findById(saved.id!!).get()
        val instance2 = repository.findById(saved.id!!).get()

        instance1.status = ReconcileStatus.MATCHED
        repository.save(instance1)
        entityManager.flush()
        entityManager.clear()

        instance2.status = ReconcileStatus.UNMATCHED

        try {
            repository.save(instance2)
            entityManager.flush()
            throw AssertionError("Expected ObjectOptimisticLockingFailureException")
        } catch (e: ObjectOptimisticLockingFailureException) {
            assertTrue(e.message?.contains("ReconciliationTransaction") == true)
        }
    }

    @Test
    fun `unique constraint on reference prevents duplicates`() {
        val transaction1 = ReconciliationTransaction(
            reference = "UNIQUE-REF-001",
            transactionType = TransactionType.WEB_GAS_ORDER,
            externalReferenceType = ExternalReferenceType.SAP,
            amount = BigDecimal("25.00"),
            status = ReconcileStatus.PENDING,
        )

        repository.save(transaction1)
        entityManager.flush()

        val transaction2 = ReconciliationTransaction(
            reference = "UNIQUE-REF-001",
            transactionType = TransactionType.WEB_ELECTRICITY_ORDER,
            externalReferenceType = ExternalReferenceType.SALESFORCE,
            amount = BigDecimal("30.00"),
            status = ReconcileStatus.MATCHED,
        )

        repository.save(transaction2)

        try {
            entityManager.flush()
            throw AssertionError("Expected constraint violation exception")
        } catch (e: Exception) {
            assertTrue(
                e.message?.contains("constraint") == true ||
                    e.message?.contains("unique") == true ||
                    e.message?.contains("duplicate") == true ||
                    e.cause?.message?.contains("constraint") == true ||
                    e.cause?.message?.contains("unique") == true ||
                    e.cause?.message?.contains("duplicate") == true,
            )
        }
    }

    @Test
    fun `findAll returns all saved transactions`() {
        repository.deleteAll()
        entityManager.flush()

        val transaction1 = ReconciliationTransaction(
            reference = "FIND-ALL-001",
            transactionType = TransactionType.WEB_ELECTRICITY_ORDER,
            externalReferenceType = ExternalReferenceType.SAP,
            amount = BigDecimal("10.00"),
            status = ReconcileStatus.PENDING,
        )

        val transaction2 = ReconciliationTransaction(
            reference = "FIND-ALL-002",
            transactionType = TransactionType.WEB_GAS_ORDER,
            externalReferenceType = ExternalReferenceType.SALESFORCE,
            amount = BigDecimal("20.00"),
            status = ReconcileStatus.MATCHED,
        )

        repository.save(transaction1)
        repository.save(transaction2)
        entityManager.flush()

        val all = repository.findAll()
        assertTrue(all.size >= 2)
        assertTrue(all.any { it.reference == "FIND-ALL-001" })
        assertTrue(all.any { it.reference == "FIND-ALL-002" })
    }

    @Test
    fun `delete removes transaction`() {
        val transaction = ReconciliationTransaction(
            reference = "DELETE-TEST-001",
            transactionType = TransactionType.WEB_BROADBAND_ORDER,
            externalReferenceType = ExternalReferenceType.ZENDESK,
            amount = BigDecimal("15.00"),
            status = ReconcileStatus.PENDING,
        )

        val saved = repository.save(transaction)
        entityManager.flush()
        assertNotNull(saved.id)

        repository.deleteById(saved.id!!)
        entityManager.flush()

        val found = repository.findById(saved.id!!)
        assertTrue(found.isEmpty)
    }

    @Test
    fun `all enum types can be persisted and retrieved`() {
        val transactions = listOf(
            ReconciliationTransaction(
                reference = "ENUM-TEST-001",
                transactionType = TransactionType.WEB_ELECTRICITY_ORDER,
                externalReferenceType = ExternalReferenceType.SAP,
                amount = BigDecimal("1.00"),
                status = ReconcileStatus.PENDING,
            ),
            ReconciliationTransaction(
                reference = "ENUM-TEST-002",
                transactionType = TransactionType.WEB_GAS_ORDER,
                externalReferenceType = ExternalReferenceType.SALESFORCE,
                amount = BigDecimal("2.00"),
                status = ReconcileStatus.MATCHED,
            ),
            ReconciliationTransaction(
                reference = "ENUM-TEST-003",
                transactionType = TransactionType.WEB_BROADBAND_ORDER,
                externalReferenceType = ExternalReferenceType.ZENDESK,
                amount = BigDecimal("3.00"),
                status = ReconcileStatus.UNMATCHED,
            ),
            ReconciliationTransaction(
                reference = "ENUM-TEST-004",
                transactionType = TransactionType.WEB_ELECTRICITY_ORDER,
                externalReferenceType = ExternalReferenceType.SAP,
                amount = BigDecimal("4.00"),
                status = ReconcileStatus.EXCEPTION,
            ),
        )

        transactions.forEach { repository.save(it) }
        entityManager.flush()
        entityManager.clear()

        val retrieved = transactions.map { repository.findByReference(it.reference)!! }

        assertEquals(TransactionType.WEB_ELECTRICITY_ORDER, retrieved[0].transactionType)
        assertEquals(TransactionType.WEB_GAS_ORDER, retrieved[1].transactionType)
        assertEquals(TransactionType.WEB_BROADBAND_ORDER, retrieved[2].transactionType)

        assertEquals(ExternalReferenceType.SAP, retrieved[0].externalReferenceType)
        assertEquals(ExternalReferenceType.SALESFORCE, retrieved[1].externalReferenceType)
        assertEquals(ExternalReferenceType.ZENDESK, retrieved[2].externalReferenceType)

        assertEquals(ReconcileStatus.PENDING, retrieved[0].status)
        assertEquals(ReconcileStatus.MATCHED, retrieved[1].status)
        assertEquals(ReconcileStatus.UNMATCHED, retrieved[2].status)
        assertEquals(ReconcileStatus.EXCEPTION, retrieved[3].status)
    }

    @Test
    fun `index on reference column exists`() {
        val indexes = jdbcTemplate.query(
            """
            SELECT indexname
            FROM pg_indexes
            WHERE tablename = 'reconciliation_transaction' AND indexname = 'idx_reference'
            """.trimIndent(),
        ) { rs, _ -> rs.getString("indexname") }

        assertTrue(indexes.isNotEmpty())
        assertEquals("idx_reference", indexes[0])
    }

    @Test
    fun `index on external_reference column exists`() {
        val indexes = jdbcTemplate.query(
            """
            SELECT indexname
            FROM pg_indexes
            WHERE tablename = 'reconciliation_transaction' AND indexname = 'idx_external_ref'
            """.trimIndent(),
        ) { rs, _ -> rs.getString("indexname") }

        assertTrue(indexes.isNotEmpty())
        assertEquals("idx_external_ref", indexes[0])
    }
}
