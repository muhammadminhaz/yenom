package com.muhammadminhaz.yenombackend.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Internal DTO representing what Claude extracts from a raw financial message.
 */
@Data
@NoArgsConstructor
public class ParsedTransactionDTO {
    private boolean isFinancialMessage;
    private BigDecimal amount;
    private String currency;
    private String transactionDate; // ISO-8601 date string
    private String description;
    private String category;
    private String type; // INCOME | EXPENSE
    private boolean isHaram;
    private String haramReason;
    private double aiConfidence;
}
