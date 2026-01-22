package com.muhammadminhaz.yenombackend.model;

import com.fasterxml.uuid.Generators;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
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
@Table(name = "transactions", indexes = {
        @Index(name = "idx_transactions_user_id", columnList = "user_id")
})
public class Transaction {
    @Id
    @Column(columnDefinition = "uuid", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @NotNull
    @DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    @NotBlank
    @Size(max = 3)
    @Column(nullable = false, length = 3)
    private String currency; // e.g., USD, EUR, INR

    @NotNull
    @PastOrPresent
    @Column(nullable = false)
    private LocalDate transactionDate;

    @NotBlank
    @Size(max = 255)
    @Column(nullable = false)
    private String description;

    @Size(max = 100)
    private String category;

    @Enumerated(EnumType.STRING)
    @NotNull
    @Column(nullable = false)
    private TransactionType type; // INCOME, EXPENSE

    @Column(nullable = false, columnDefinition = "transaction_status")
    @Enumerated(EnumType.STRING)
    private TransactionStatus status;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        if (this.id == null) {
            this.id = Generators.timeBasedGenerator().generate();
        }
    }
}

