package com.webtransaction.microsite.domain

import io.hypersistence.utils.hibernate.type.json.JsonBinaryType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EntityListeners
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.hibernate.annotations.Type
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "web_transaction")
@EntityListeners(AuditingEntityListener::class)
data class WebTransaction(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false, length = 100)
    val reference: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false)
    val transactionType: TransactionType,

    @Type(JsonBinaryType::class)
    @Column(name = "original_payload", columnDefinition = "jsonb")
    val originalPayload: Map<String, Any?>? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "external_reference_type", nullable = false)
    val externalReferenceType: ExternalReferenceType,

    @Column(name = "external_reference_number", length = 255)
    var externalReferenceNumber: String? = null,

    @Type(JsonBinaryType::class)
    @Column(name = "reconcile_payload", columnDefinition = "jsonb")
    var reconcilePayload: Map<String, Any?>? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "reconcile_status", nullable = false)
    var reconcileStatus: ReconcileStatus,

    @CreatedDate
    @Column(nullable = false, updatable = false)
    val created: LocalDateTime? = null,

    @LastModifiedDate
    @Column(nullable = false)
    val updated: LocalDateTime? = null
)
