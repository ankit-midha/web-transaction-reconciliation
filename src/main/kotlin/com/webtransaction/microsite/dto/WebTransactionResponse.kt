package com.webtransaction.microsite.dto

import com.webtransaction.microsite.domain.ExternalReferenceType
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import com.webtransaction.microsite.domain.WebTransaction
import java.time.LocalDateTime

data class WebTransactionResponse(
    val id: Long,
    val reference: String,
    val transactionType: TransactionType,
    val originalPayload: Map<String, Any?>?,
    val externalReferenceType: ExternalReferenceType,
    val externalReferenceNumber: String?,
    val reconcilePayload: Map<String, Any?>?,
    val reconcileStatus: ReconcileStatus,
    val created: LocalDateTime,
    val updated: LocalDateTime
) {
    companion object {
        fun from(transaction: WebTransaction): WebTransactionResponse {
            return WebTransactionResponse(
                id = transaction.id!!,
                reference = transaction.reference,
                transactionType = transaction.transactionType,
                originalPayload = transaction.originalPayload,
                externalReferenceType = transaction.externalReferenceType,
                externalReferenceNumber = transaction.externalReferenceNumber,
                reconcilePayload = transaction.reconcilePayload,
                reconcileStatus = transaction.reconcileStatus,
                created = transaction.created!!,
                updated = transaction.updated!!
            )
        }
    }
}
