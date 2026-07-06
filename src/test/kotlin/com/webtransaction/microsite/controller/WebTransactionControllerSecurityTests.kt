package com.webtransaction.microsite.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.ninjasquad.springmockk.MockkBean
import com.webtransaction.microsite.dto.CreateWebTransactionRequest
import com.webtransaction.microsite.dto.UpdateWebTransactionRequest
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import com.webtransaction.microsite.domain.WebTransaction
import com.webtransaction.microsite.service.WebTransactionService
import io.mockk.every
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.context.TestPropertySource
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import java.time.LocalDateTime

@WebMvcTest(WebTransactionController::class)
@Import(GlobalExceptionHandler::class)
@TestPropertySource(properties = ["security.enabled=false"])
class WebTransactionControllerSecurityTests {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @MockkBean
    private lateinit var service: WebTransactionService

    private val sampleTransaction = WebTransaction(
        id = 1L,
        reference = "REF-001",
        transactionType = TransactionType.PAYMENT,
        originalPayload = """{"amount": 100}""",
        externalReferenceType = "INVOICE",
        externalReferenceNumber = "INV-001",
        reconcilePayload = null,
        reconcileStatus = ReconcileStatus.PENDING,
        createdAt = LocalDateTime.now(),
        updatedAt = LocalDateTime.now()
    )

    @Test
    @WithMockUser(authorities = ["SCOPE_read:web-transaction"])
    fun `GET by id with read scope returns 200`() {
        every { service.getById(1L) } returns sampleTransaction

        mockMvc.perform(get("/v1/webtransaction/1"))
            .andExpect(status().isOk)
    }

    @Test
    @WithMockUser(authorities = ["SCOPE_read:web-transaction"])
    fun `GET by reference with read scope returns 200`() {
        every { service.getByReference("REF-001") } returns sampleTransaction

        mockMvc.perform(get("/v1/webtransaction/reference/REF-001"))
            .andExpect(status().isOk)
    }

    @Test
    @WithMockUser(authorities = ["SCOPE_write:web-transaction"])
    fun `POST with write scope returns 201`() {
        val request = CreateWebTransactionRequest(
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = """{"amount": 100}""",
            externalReferenceType = "INVOICE",
            externalReferenceNumber = "INV-001",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        every {
            service.create(
                reference = "REF-001",
                transactionType = TransactionType.PAYMENT,
                originalPayload = """{"amount": 100}""",
                externalReferenceType = "INVOICE",
                externalReferenceNumber = "INV-001",
                reconcilePayload = null,
                reconcileStatus = ReconcileStatus.PENDING
            )
        } returns sampleTransaction

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
    }

    @Test
    @WithMockUser(authorities = ["SCOPE_write:web-transaction"])
    fun `PUT with write scope returns 200`() {
        val request = UpdateWebTransactionRequest(
            reconcileStatus = ReconcileStatus.RECONCILED,
            externalReferenceNumber = "INV-001-UPDATED",
            reconcilePayload = """{"reconciled": true}"""
        )

        every {
            service.updateByReference(
                reference = "REF-001",
                reconcileStatus = ReconcileStatus.RECONCILED,
                externalReferenceNumber = "INV-001-UPDATED",
                reconcilePayload = """{"reconciled": true}"""
            )
        } returns sampleTransaction

        mockMvc.perform(
            put("/v1/webtransaction/reference/REF-001")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
    }

    @Test
    @WithMockUser(authorities = ["SCOPE_write:web-transaction"])
    fun `GET with write-only scope returns 403`() {
        mockMvc.perform(get("/v1/webtransaction/1"))
            .andExpect(status().isForbidden)
            .andExpect(jsonPath("$.error").value("Access denied"))
    }

    @Test
    @WithMockUser(authorities = ["SCOPE_read:web-transaction"])
    fun `POST with read-only scope returns 403`() {
        val request = CreateWebTransactionRequest(
            reference = "REF-001",
            transactionType = TransactionType.PAYMENT,
            originalPayload = """{"amount": 100}""",
            externalReferenceType = "INVOICE",
            externalReferenceNumber = "INV-001",
            reconcilePayload = null,
            reconcileStatus = ReconcileStatus.PENDING
        )

        mockMvc.perform(
            post("/v1/webtransaction")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isForbidden)
            .andExpect(jsonPath("$.error").value("Access denied"))
    }

    @Test
    @WithMockUser(authorities = ["SCOPE_read:web-transaction"])
    fun `PUT with read-only scope returns 403`() {
        val request = UpdateWebTransactionRequest(
            reconcileStatus = ReconcileStatus.RECONCILED,
            externalReferenceNumber = "INV-001-UPDATED",
            reconcilePayload = """{"reconciled": true}"""
        )

        mockMvc.perform(
            put("/v1/webtransaction/reference/REF-001")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isForbidden)
            .andExpect(jsonPath("$.error").value("Access denied"))
    }

    @Test
    fun `unauthenticated request returns 401`() {
        mockMvc.perform(get("/v1/webtransaction/1"))
            .andExpect(status().isUnauthorized)
    }
}
