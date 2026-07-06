package com.webtransaction.microsite.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.Version
import java.math.BigDecimal
import java.time.LocalDateTime

@Entity
@Table(name = "reconciliation_transaction")
class ReconciliationTransaction(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(unique = true, nullable = false)
    var reference: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false)
    var transactionType: TransactionType,

    @Enumerated(EnumType.STRING)
    @Column(name = "external_reference_type", nullable = false)
    var externalReferenceType: ExternalReferenceType,

    @Column(name = "external_reference")
    var externalReference: String? = null,

    @Column(nullable = false)
    var amount: BigDecimal,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: ReconcileStatus,

    @Column(nullable = false)
    var created: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = false)
    var updated: LocalDateTime = LocalDateTime.now(),

    @Version
    @Column(nullable = false)
    var version: Long = 0,
)
