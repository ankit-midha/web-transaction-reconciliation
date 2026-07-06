package com.webtransaction.microsite.dto

import com.webtransaction.microsite.domain.ReconcileStatus
import jakarta.validation.constraints.Size

data class UpdateWebTransactionRequest(
    val reconcileStatus: ReconcileStatus? = null,

    @field:Size(max = 255, message = "External reference number must not exceed 255 characters")
    val externalReferenceNumber: String? = null,

    val reconcilePayload: Map<String, Any?>? = null
)
