package com.webtransaction.microsite.controller

import com.webtransaction.microsite.dto.CreateWebTransactionRequest
import com.webtransaction.microsite.dto.UpdateWebTransactionRequest
import com.webtransaction.microsite.dto.WebTransactionResponse
import com.webtransaction.microsite.service.WebTransactionService
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.servlet.support.ServletUriComponentsBuilder
import java.net.URI

@RestController
@RequestMapping("/v1/webtransaction")
class WebTransactionController(
    private val service: WebTransactionService
) {
    @PostMapping
    @PreAuthorize("hasAuthority('SCOPE_write:web-transaction')")
    fun create(@Valid @RequestBody request: CreateWebTransactionRequest): ResponseEntity<WebTransactionResponse> {
        val transaction = service.create(
            reference = request.reference,
            transactionType = request.transactionType,
            originalPayload = request.originalPayload,
            externalReferenceType = request.externalReferenceType,
            externalReferenceNumber = request.externalReferenceNumber,
            reconcilePayload = request.reconcilePayload,
            reconcileStatus = request.reconcileStatus
        )
        val response = WebTransactionResponse.from(transaction)
        val location: URI = ServletUriComponentsBuilder
            .fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(transaction.id)
            .toUri()
        return ResponseEntity.created(location).body(response)
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('SCOPE_read:web-transaction')")
    fun getById(@PathVariable id: Long): ResponseEntity<WebTransactionResponse> {
        val transaction = service.getById(id)
        return ResponseEntity.ok(WebTransactionResponse.from(transaction))
    }

    @GetMapping("/reference/{reference}")
    @PreAuthorize("hasAuthority('SCOPE_read:web-transaction')")
    fun getByReference(@PathVariable reference: String): ResponseEntity<WebTransactionResponse> {
        val transaction = service.getByReference(reference)
        return ResponseEntity.ok(WebTransactionResponse.from(transaction))
    }

    @PutMapping("/reference/{reference}")
    @PreAuthorize("hasAuthority('SCOPE_write:web-transaction')")
    fun updateByReference(
        @PathVariable reference: String,
        @Valid @RequestBody request: UpdateWebTransactionRequest
    ): ResponseEntity<WebTransactionResponse> {
        val transaction = service.updateByReference(
            reference = reference,
            reconcileStatus = request.reconcileStatus,
            externalReferenceNumber = request.externalReferenceNumber,
            reconcilePayload = request.reconcilePayload
        )
        return ResponseEntity.ok(WebTransactionResponse.from(transaction))
    }
}
