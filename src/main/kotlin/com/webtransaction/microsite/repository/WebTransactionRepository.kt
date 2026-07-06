package com.webtransaction.microsite.repository

import com.webtransaction.microsite.domain.WebTransaction
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface WebTransactionRepository : JpaRepository<WebTransaction, Long> {
    fun findByReference(reference: String): WebTransaction?
}
