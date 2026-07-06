package com.webtransaction.microsite.repository

import com.webtransaction.microsite.entity.ReconciliationTransaction
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface ReconciliationTransactionRepository : JpaRepository<ReconciliationTransaction, Long> {
    fun findByReference(reference: String): ReconciliationTransaction?
}
