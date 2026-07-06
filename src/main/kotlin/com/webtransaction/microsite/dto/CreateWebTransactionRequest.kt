package com.webtransaction.microsite.dto

import com.webtransaction.microsite.domain.ExternalReferenceType
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size

data class CreateWebTransactionRequest(
    @field:NotBlank(message = "Reference is required")
    @field:Size(max = 100, message = "Reference must not exceed 100 characters")
    val reference: String,

    @field:NotNull(message = "Transaction type is required")
    val transactionType: TransactionType,

    val originalPayload: Map<String, Any?>? = null,

    @field:NotNull(message = "External reference type is required")
    val externalReferenceType: ExternalReferenceType,

    @field:Size(max = 255, message = "External reference number must not exceed 255 characters")
    val externalReferenceNumber: String? = null,

    val reconcilePayload: Map<String, Any?>? = null,

    @field:NotNull(message = "Reconcile status is required")
    val reconcileStatus: ReconcileStatus
)
