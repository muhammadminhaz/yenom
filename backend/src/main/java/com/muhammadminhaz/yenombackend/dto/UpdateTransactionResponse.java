package com.muhammadminhaz.yenombackend.dto;

import com.muhammadminhaz.yenombackend.model.TransactionStatus;
import com.muhammadminhaz.yenombackend.model.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateTransactionResponse {
    private String message;
    private UUID id;
    private BigDecimal amount;
    private String currency;
    private LocalDate transactionDate;
    private String description;
    private String category;
    private TransactionType type;
    private TransactionStatus status;
}
