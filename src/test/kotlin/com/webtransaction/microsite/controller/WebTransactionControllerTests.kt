package com.webtransaction.microsite.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.ninjasquad.springmockk.MockkBean
import com.webtransaction.microsite.domain.ExternalReferenceType
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import com.webtransaction.microsite.domain.WebTransaction
import com.webtransaction.microsite.dto.CreateWebTransactionRequest
import com.webtransaction.microsite.dto.UpdateWebTransactionRequest
import com.webtransaction.microsite.exception.EntityNotFoundException
import com.webtransaction.microsite.service.WebTransactionService
import io.mockk.every
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.header
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import java.time.LocalDateTime

@WebMvcTest(WebTransactionController::class, GlobalExceptionHandler::class)
class WebTransactionControllerTests {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @MockkBean
    private lateinit var service: WebTransactionService

    @Test
    fun `POST should create transaction and return 201 with Location header`() {
        val request = CreateWebTransactionRequest(
            reference = "REF-001",
            transactionType = TransactionType.PURCHASE,
            originalPayload = mapOf("key" to "value"),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-123",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val savedTransaction = WebTransaction(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PURCHASE,
            originalPayload = mapOf("key" to "value"),
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-123",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.of(2026, 7, 6, 10, 0, 0),
            updated = LocalDateTime.of(2026, 7, 6, 10, 0, 0)
        )

        every {
            service.create(
                reference = "REF-001",
                transactionType = TransactionType.PURCHASE,
                originalPayload = mapOf("key" to "value"),
                externalReferenceType = ExternalReferenceType.ORDER_ID,
                externalReferenceNumber = "ORDER-123",
                reconcilePayload = null,
                reconcileStatus = ReconcileStatus.PENDING
            )
        } returns savedTransaction

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
            .andExpect(header().exists("Location"))
            .andExpect(header().string("Location", "http://localhost/v1/webtransaction/1"))
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.reference").value("REF-001"))
            .andExpect(jsonPath("$.transactionType").value("PURCHASE"))
            .andExpect(jsonPath("$.originalPayload.key").value("value"))
            .andExpect(jsonPath("$.externalReferenceType").value("ORDER_ID"))
            .andExpect(jsonPath("$.externalReferenceNumber").value("ORDER-123"))
            .andExpect(jsonPath("$.reconcileStatus").value("PENDING"))
            .andExpect(jsonPath("$.created").value("2026-07-06T10:00:00"))
            .andExpect(jsonPath("$.updated").value("2026-07-06T10:00:00"))

        verify(exactly = 1) {
            service.create(
                reference = "REF-001",
                transactionType = TransactionType.PURCHASE,
                originalPayload = mapOf("key" to "value"),
                externalReferenceType = ExternalReferenceType.ORDER_ID,
                externalReferenceNumber = "ORDER-123",
                reconcilePayload = null,
                reconcileStatus = ReconcileStatus.PENDING
            )
        }
    }

    @Test
    fun `POST should return 400 when reference is blank`() {
        val request = mapOf(
            "reference" to "",
            "transactionType" to "PURCHASE",
            "externalReferenceType" to "ORDER_ID",
            "reconcileStatus" to "PENDING"
        )

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isBadRequest)
            .andExpect(jsonPath("$.error").value("Validation failed"))
            .andExpect(jsonPath("$.details.reference").exists())
    }

    @Test
    fun `POST should return 400 when reference exceeds max length`() {
        val longReference = "A".repeat(101)
        val request = mapOf(
            "reference" to longReference,
            "transactionType" to "PURCHASE",
            "externalReferenceType" to "ORDER_ID",
            "reconcileStatus" to "PENDING"
        )

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isBadRequest)
            .andExpect(jsonPath("$.error").value("Validation failed"))
            .andExpect(jsonPath("$.details.reference").value("Reference must not exceed 100 characters"))
    }

    @Test
    fun `POST should return 400 when required fields are missing`() {
        val request = mapOf("reference" to "REF-001")

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isBadRequest)
            .andExpect(jsonPath("$.error").value("Validation failed"))
            .andExpect(jsonPath("$.details").isMap)
    }

    @Test
    fun `POST should return 400 when invalid enum value provided`() {
        val request = mapOf(
            "reference" to "REF-001",
            "transactionType" to "INVALID_TYPE",
            "externalReferenceType" to "ORDER_ID",
            "reconcileStatus" to "PENDING"
        )

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isBadRequest)
            .andExpect(jsonPath("$.error").exists())
    }

    @Test
    fun `POST should return 400 when externalReferenceNumber exceeds max length`() {
        val longReferenceNumber = "A".repeat(256)
        val request = mapOf(
            "reference" to "REF-001",
            "transactionType" to "PURCHASE",
            "externalReferenceType" to "ORDER_ID",
            "externalReferenceNumber" to longReferenceNumber,
            "reconcileStatus" to "PENDING"
        )

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isBadRequest)
            .andExpect(jsonPath("$.error").value("Validation failed"))
            .andExpect(jsonPath("$.details.externalReferenceNumber").value("External reference number must not exceed 255 characters"))
    }

    @Test
    fun `POST should handle nested JSONB payload correctly`() {
        val nestedPayload = mapOf(
            "level1" to mapOf(
                "level2" to mapOf(
                    "level3" to listOf("a", "b", "c")
                )
            ),
            "array" to listOf(1, 2, 3)
        )

        val request = CreateWebTransactionRequest(
            reference = "REF-NESTED",
            transactionType = TransactionType.PURCHASE,
            originalPayload = nestedPayload,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val savedTransaction = WebTransaction(
            id = 2L,
            reference = "REF-NESTED",
            transactionType = TransactionType.PURCHASE,
            originalPayload = nestedPayload,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every {
            service.create(
                reference = "REF-NESTED",
                transactionType = TransactionType.PURCHASE,
                originalPayload = nestedPayload,
                externalReferenceType = ExternalReferenceType.ORDER_ID,
                externalReferenceNumber = null,
                reconcilePayload = null,
                reconcileStatus = ReconcileStatus.PENDING
            )
        } returns savedTransaction

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.originalPayload.level1.level2.level3[0]").value("a"))
            .andExpect(jsonPath("$.originalPayload.array[0]").value(1))
    }

    @Test
    fun `GET by id should return 200 with transaction`() {
        val transaction = WebTransaction(
            id = 1L,
            reference = "REF-001",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-123",
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.of(2026, 7, 6, 10, 0, 0),
            updated = LocalDateTime.of(2026, 7, 6, 10, 0, 0)
        )

        every { service.getById(1L) } returns transaction

        mockMvc.perform(get("/v1/webtransaction/1"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.reference").value("REF-001"))
            .andExpect(jsonPath("$.transactionType").value("PURCHASE"))
            .andExpect(jsonPath("$.externalReferenceType").value("ORDER_ID"))
            .andExpect(jsonPath("$.externalReferenceNumber").value("ORDER-123"))

        verify(exactly = 1) { service.getById(1L) }
    }

    @Test
    fun `GET by id should return 404 when not found`() {
        every { service.getById(999L) } throws EntityNotFoundException("Web transaction not found with id: 999")

        mockMvc.perform(get("/v1/webtransaction/999"))
            .andExpect(status().isNotFound)
            .andExpect(jsonPath("$.error").value("Web transaction not found with id: 999"))

        verify(exactly = 1) { service.getById(999L) }
    }

    @Test
    fun `GET by reference should return 200 with transaction`() {
        val transaction = WebTransaction(
            id = 1L,
            reference = "REF-SEARCH",
            transactionType = TransactionType.REFUND,
            externalReferenceType = ExternalReferenceType.PAYMENT_ID,
            reconcileStatus = ReconcileStatus.COMPLETED,
            created = LocalDateTime.of(2026, 7, 6, 10, 0, 0),
            updated = LocalDateTime.of(2026, 7, 6, 11, 0, 0)
        )

        every { service.getByReference("REF-SEARCH") } returns transaction

        mockMvc.perform(get("/v1/webtransaction/reference/REF-SEARCH"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.reference").value("REF-SEARCH"))
            .andExpect(jsonPath("$.transactionType").value("REFUND"))
            .andExpect(jsonPath("$.reconcileStatus").value("COMPLETED"))

        verify(exactly = 1) { service.getByReference("REF-SEARCH") }
    }

    @Test
    fun `GET by reference should return 404 when not found`() {
        every { service.getByReference("REF-MISSING") } throws EntityNotFoundException("Web transaction not found with reference: REF-MISSING")

        mockMvc.perform(get("/v1/webtransaction/reference/REF-MISSING"))
            .andExpect(status().isNotFound)
            .andExpect(jsonPath("$.error").value("Web transaction not found with reference: REF-MISSING"))

        verify(exactly = 1) { service.getByReference("REF-MISSING") }
    }

    @Test
    fun `PUT by reference should return 200 with updated transaction`() {
        val updateRequest = UpdateWebTransactionRequest(
            reconcileStatus = ReconcileStatus.COMPLETED,
            externalReferenceNumber = "ORDER-UPDATED",
            reconcilePayload = mapOf("result" to "success")
        )

        val updatedTransaction = WebTransaction(
            id = 1L,
            reference = "REF-UPDATE",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = "ORDER-UPDATED",
            reconcilePayload = mapOf("result" to "success"),
            reconcileStatus = ReconcileStatus.COMPLETED,
            created = LocalDateTime.of(2026, 7, 6, 10, 0, 0),
            updated = LocalDateTime.of(2026, 7, 6, 11, 30, 0)
        )

        every {
            service.updateByReference(
                reference = "REF-UPDATE",
                reconcileStatus = ReconcileStatus.COMPLETED,
                externalReferenceNumber = "ORDER-UPDATED",
                reconcilePayload = mapOf("result" to "success")
            )
        } returns updatedTransaction

        mockMvc.perform(
            put("/v1/webtransaction/reference/REF-UPDATE")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updateRequest))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.reference").value("REF-UPDATE"))
            .andExpect(jsonPath("$.externalReferenceNumber").value("ORDER-UPDATED"))
            .andExpect(jsonPath("$.reconcileStatus").value("COMPLETED"))
            .andExpect(jsonPath("$.reconcilePayload.result").value("success"))

        verify(exactly = 1) {
            service.updateByReference(
                reference = "REF-UPDATE",
                reconcileStatus = ReconcileStatus.COMPLETED,
                externalReferenceNumber = "ORDER-UPDATED",
                reconcilePayload = mapOf("result" to "success")
            )
        }
    }

    @Test
    fun `PUT by reference should return 404 when not found`() {
        val updateRequest = UpdateWebTransactionRequest(
            reconcileStatus = ReconcileStatus.COMPLETED
        )

        every {
            service.updateByReference(
                reference = "REF-NOTFOUND",
                reconcileStatus = ReconcileStatus.COMPLETED,
                externalReferenceNumber = null,
                reconcilePayload = null
            )
        } throws EntityNotFoundException("Web transaction not found with reference: REF-NOTFOUND")

        mockMvc.perform(
            put("/v1/webtransaction/reference/REF-NOTFOUND")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updateRequest))
        )
            .andExpect(status().isNotFound)
            .andExpect(jsonPath("$.error").value("Web transaction not found with reference: REF-NOTFOUND"))

        verify(exactly = 1) {
            service.updateByReference(
                reference = "REF-NOTFOUND",
                reconcileStatus = ReconcileStatus.COMPLETED,
                externalReferenceNumber = null,
                reconcilePayload = null
            )
        }
    }

    @Test
    fun `PUT should return 400 when externalReferenceNumber exceeds max length`() {
        val longReferenceNumber = "A".repeat(256)
        val updateRequest = mapOf(
            "externalReferenceNumber" to longReferenceNumber
        )

        mockMvc.perform(
            put("/v1/webtransaction/reference/REF-UPDATE")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updateRequest))
        )
            .andExpect(status().isBadRequest)
            .andExpect(jsonPath("$.error").value("Validation failed"))
            .andExpect(jsonPath("$.details.externalReferenceNumber").value("External reference number must not exceed 255 characters"))
    }

    @Test
    fun `PUT with all null fields should still call service`() {
        val updateRequest = UpdateWebTransactionRequest(
            reconcileStatus = null,
            externalReferenceNumber = null,
            reconcilePayload = null
        )

        val transaction = WebTransaction(
            id = 1L,
            reference = "REF-NULLUPDATE",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every {
            service.updateByReference(
                reference = "REF-NULLUPDATE",
                reconcileStatus = null,
                externalReferenceNumber = null,
                reconcilePayload = null
            )
        } returns transaction

        mockMvc.perform(
            put("/v1/webtransaction/reference/REF-NULLUPDATE")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updateRequest))
        )
            .andExpect(status().isOk)

        verify(exactly = 1) {
            service.updateByReference(
                reference = "REF-NULLUPDATE",
                reconcileStatus = null,
                externalReferenceNumber = null,
                reconcilePayload = null
            )
        }
    }

    @Test
    fun `POST should accept transaction with all optional fields null`() {
        val request = CreateWebTransactionRequest(
            reference = "REF-MINIMAL",
            transactionType = TransactionType.PURCHASE,
            originalPayload = null,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        val savedTransaction = WebTransaction(
            id = 3L,
            reference = "REF-MINIMAL",
            transactionType = TransactionType.PURCHASE,
            originalPayload = null,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            externalReferenceNumber = null,
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every {
            service.create(
                reference = "REF-MINIMAL",
                transactionType = TransactionType.PURCHASE,
                originalPayload = null,
                externalReferenceType = ExternalReferenceType.ORDER_ID,
                externalReferenceNumber = null,
                reconcilePayload = null,
                reconcileStatus = ReconcileStatus.PENDING
            )
        } returns savedTransaction

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.id").value(3))
            .andExpect(jsonPath("$.reference").value("REF-MINIMAL"))
            .andExpect(jsonPath("$.originalPayload").isEmpty)
            .andExpect(jsonPath("$.externalReferenceNumber").isEmpty)
            .andExpect(jsonPath("$.reconcilePayload").isEmpty)
    }

    @Test
    fun `GET by reference should handle special characters in path`() {
        val transaction = WebTransaction(
            id = 1L,
            reference = "REF-WITH-DASH",
            transactionType = TransactionType.PURCHASE,
            externalReferenceType = ExternalReferenceType.ORDER_ID,
            reconcileStatus = ReconcileStatus.PENDING,
            created = LocalDateTime.now(),
            updated = LocalDateTime.now()
        )

        every { service.getByReference("REF-WITH-DASH") } returns transaction

        mockMvc.perform(get("/v1/webtransaction/reference/REF-WITH-DASH"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.reference").value("REF-WITH-DASH"))

        verify(exactly = 1) { service.getByReference("REF-WITH-DASH") }
    }
}
