package com.webtransaction.microsite.service

import com.webtransaction.microsite.domain.ExternalReferenceType
import com.webtransaction.microsite.domain.ReconcileStatus
import com.webtransaction.microsite.domain.TransactionType
import com.webtransaction.microsite.domain.WebTransaction
import com.webtransaction.microsite.exception.EntityNotFoundException
import com.webtransaction.microsite.repository.WebTransactionRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class WebTransactionService(
    private val repository: WebTransactionRepository
) {
    fun create(
        reference: String,
        transactionType: TransactionType,
        originalPayload: Map<String, Any?>?,
        externalReferenceType: ExternalReferenceType,
        externalReferenceNumber: String?,
        reconcilePayload: Map<String, Any?>?,
        reconcileStatus: ReconcileStatus
    ): WebTransaction {
        val transaction = WebTransaction(
            reference = reference,
            transactionType = transactionType,
            originalPayload = originalPayload,
            externalReferenceType = externalReferenceType,
            externalReferenceNumber = externalReferenceNumber,
            reconcilePayload = reconcilePayload,
            reconcileStatus = reconcileStatus
        )
        return repository.save(transaction)
    }

    @Transactional(readOnly = true)
    fun getById(id: Long): WebTransaction {
        return repository.findById(id).orElseThrow {
            EntityNotFoundException("Web transaction not found with id: $id")
        }
    }

    @Transactional(readOnly = true)
    fun getByReference(reference: String): WebTransaction {
        return repository.findByReference(reference)
            ?: throw EntityNotFoundException("Web transaction not found with reference: $reference")
    }

    fun updateByReference(
        reference: String,
        reconcileStatus: ReconcileStatus?,
        externalReferenceNumber: String?,
        reconcilePayload: Map<String, Any?>?
    ): WebTransaction {
        val transaction = getByReference(reference)
        reconcileStatus?.let { transaction.reconcileStatus = it }
        externalReferenceNumber?.let { transaction.externalReferenceNumber = it }
        reconcilePayload?.let { transaction.reconcilePayload = it }
        return repository.save(transaction)
    }
}
