package com.webtransaction.microsite.entity

import jakarta.persistence.Column
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Version
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.math.BigDecimal
import java.time.LocalDateTime
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ReconciliationTransactionTests {

    @Test
    fun `TransactionType enum values exist`() {
        assertEquals(TransactionType.WEB_ELECTRICITY_ORDER, TransactionType.valueOf("WEB_ELECTRICITY_ORDER"))
        assertEquals(TransactionType.WEB_GAS_ORDER, TransactionType.valueOf("WEB_GAS_ORDER"))
        assertEquals(TransactionType.WEB_BROADBAND_ORDER, TransactionType.valueOf("WEB_BROADBAND_ORDER"))
        assertEquals(3, TransactionType.entries.size)
    }

    @Test
    fun `ExternalReferenceType enum values exist`() {
        assertEquals(ExternalReferenceType.SAP, ExternalReferenceType.valueOf("SAP"))
        assertEquals(ExternalReferenceType.SALESFORCE, ExternalReferenceType.valueOf("SALESFORCE"))
        assertEquals(ExternalReferenceType.ZENDESK, ExternalReferenceType.valueOf("ZENDESK"))
        assertEquals(3, ExternalReferenceType.entries.size)
    }

    @Test
    fun `ReconcileStatus enum values exist`() {
        assertEquals(ReconcileStatus.PENDING, ReconcileStatus.valueOf("PENDING"))
        assertEquals(ReconcileStatus.MATCHED, ReconcileStatus.valueOf("MATCHED"))
        assertEquals(ReconcileStatus.UNMATCHED, ReconcileStatus.valueOf("UNMATCHED"))
        assertEquals(ReconcileStatus.EXCEPTION, ReconcileStatus.valueOf("EXCEPTION"))
        assertEquals(4, ReconcileStatus.entries.size)
    }

    @Test
    fun `TransactionType valueOf throws on invalid value`() {
        assertThrows<IllegalArgumentException> {
            TransactionType.valueOf("INVALID_TYPE")
        }
    }

    @Test
    fun `ExternalReferenceType valueOf throws on invalid value`() {
        assertThrows<IllegalArgumentException> {
            ExternalReferenceType.valueOf("INVALID_TYPE")
        }
    }

    @Test
    fun `ReconcileStatus valueOf throws on invalid value`() {
        assertThrows<IllegalArgumentException> {
            ReconcileStatus.valueOf("INVALID_STATUS")
        }
    }

    @Test
    fun `ReconciliationTransaction can be instantiated`() {
        val now = LocalDateTime.now()
        val transaction = ReconciliationTransaction(
            reference = "REF-001",
            transactionType = TransactionType.WEB_ELECTRICITY_ORDER,
            externalReferenceType = ExternalReferenceType.SAP,
            externalReference = "SAP-12345",
            amount = BigDecimal("99.99"),
            status = ReconcileStatus.PENDING,
            created = now,
            updated = now,
        )

        assertNull(transaction.id)
        assertEquals("REF-001", transaction.reference)
        assertEquals(TransactionType.WEB_ELECTRICITY_ORDER, transaction.transactionType)
        assertEquals(ExternalReferenceType.SAP, transaction.externalReferenceType)
        assertEquals("SAP-12345", transaction.externalReference)
        assertEquals(BigDecimal("99.99"), transaction.amount)
        assertEquals(ReconcileStatus.PENDING, transaction.status)
        assertEquals(now, transaction.created)
        assertEquals(now, transaction.updated)
        assertEquals(0L, transaction.version)
    }

    @Test
    fun `ReconciliationTransaction allows null external reference`() {
        val transaction = ReconciliationTransaction(
            reference = "REF-002",
            transactionType = TransactionType.WEB_GAS_ORDER,
            externalReferenceType = ExternalReferenceType.SALESFORCE,
            externalReference = null,
            amount = BigDecimal("50.00"),
            status = ReconcileStatus.MATCHED,
        )

        assertNull(transaction.externalReference)
    }

    @Test
    fun `ReconciliationTransaction fields are mutable`() {
        val transaction = ReconciliationTransaction(
            reference = "REF-003",
            transactionType = TransactionType.WEB_BROADBAND_ORDER,
            externalReferenceType = ExternalReferenceType.ZENDESK,
            amount = BigDecimal("100.00"),
            status = ReconcileStatus.PENDING,
        )

        transaction.reference = "REF-003-UPDATED"
        transaction.status = ReconcileStatus.MATCHED
        transaction.amount = BigDecimal("150.00")

        assertEquals("REF-003-UPDATED", transaction.reference)
        assertEquals(ReconcileStatus.MATCHED, transaction.status)
        assertEquals(BigDecimal("150.00"), transaction.amount)
    }

    @Test
    fun `ReconciliationTransaction has Version annotation`() {
        val versionField = ReconciliationTransaction::class.java.getDeclaredField("version")
        val versionAnnotation = versionField.getAnnotation(Version::class.java)
        assertNotNull(versionAnnotation)
    }

    @Test
    fun `ReconciliationTransaction has Id annotation with IDENTITY strategy`() {
        val idField = ReconciliationTransaction::class.java.getDeclaredField("id")
        val idAnnotation = idField.getAnnotation(Id::class.java)
        val generatedValueAnnotation = idField.getAnnotation(GeneratedValue::class.java)

        assertNotNull(idAnnotation)
        assertNotNull(generatedValueAnnotation)
        assertEquals(GenerationType.IDENTITY, generatedValueAnnotation.strategy)
    }

    @Test
    fun `ReconciliationTransaction has Enumerated annotations with STRING type`() {
        val transactionTypeField = ReconciliationTransaction::class.java.getDeclaredField("transactionType")
        val externalRefTypeField = ReconciliationTransaction::class.java.getDeclaredField("externalReferenceType")
        val statusField = ReconciliationTransaction::class.java.getDeclaredField("status")

        val transactionTypeEnum = transactionTypeField.getAnnotation(Enumerated::class.java)
        val externalRefTypeEnum = externalRefTypeField.getAnnotation(Enumerated::class.java)
        val statusEnum = statusField.getAnnotation(Enumerated::class.java)

        assertNotNull(transactionTypeEnum)
        assertNotNull(externalRefTypeEnum)
        assertNotNull(statusEnum)
        assertEquals(EnumType.STRING, transactionTypeEnum.value)
        assertEquals(EnumType.STRING, externalRefTypeEnum.value)
        assertEquals(EnumType.STRING, statusEnum.value)
    }

    @Test
    fun `ReconciliationTransaction reference field has unique and nullable constraints`() {
        val referenceField = ReconciliationTransaction::class.java.getDeclaredField("reference")
        val columnAnnotation = referenceField.getAnnotation(Column::class.java)

        assertNotNull(columnAnnotation)
        assertTrue(columnAnnotation.unique)
        assertTrue(!columnAnnotation.nullable)
    }

    @Test
    fun `ReconciliationTransaction has correct column mappings`() {
        val transactionTypeField = ReconciliationTransaction::class.java.getDeclaredField("transactionType")
        val externalRefTypeField = ReconciliationTransaction::class.java.getDeclaredField("externalReferenceType")

        val transactionTypeColumn = transactionTypeField.getAnnotation(Column::class.java)
        val externalRefTypeColumn = externalRefTypeField.getAnnotation(Column::class.java)

        assertEquals("transaction_type", transactionTypeColumn.name)
        assertEquals("external_reference_type", externalRefTypeColumn.name)
    }
}
