package com.muhammadminhaz.yenombackend.model;

import com.fasterxml.uuid.Generators;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "transaction_suggestions", indexes = {
        @Index(name = "idx_suggestions_user_status", columnList = "user_id, status")
})
public class TransactionSuggestion {

    @Id
    @Column(columnDefinition = "uuid", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(nullable = false, length = 10)
    private String source; // GMAIL | SMS

    @Column(name = "raw_message", nullable = false, columnDefinition = "TEXT")
    private String rawMessage;

    @Column(precision = 10, scale = 2)
    private BigDecimal amount;

    @Column(length = 3)
    private String currency;

    @Column(name = "transaction_date")
    private LocalDate transactionDate;

    @Column(length = 255)
    private String description;

    @Column(length = 100)
    private String category;

    @Column(length = 10)
    private String type; // INCOME | EXPENSE

    @Column(name = "is_haram")
    @Builder.Default
    private Boolean isHaram = false;

    @Column(name = "haram_reason", length = 255)
    private String haramReason;

    @Column(name = "ai_confidence", precision = 3, scale = 2)
    private BigDecimal aiConfidence;

    @Column(nullable = false, length = 10)
    @Builder.Default
    private String status = "PENDING"; // PENDING | ACCEPTED | REJECTED

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @PrePersist
    public void prePersist() {
        if (this.id == null) {
            this.id = Generators.timeBasedGenerator().generate();
        }
        if (this.expiresAt == null) {
            this.expiresAt = LocalDateTime.now().plusDays(7);
        }
    }
}
