package com.muhammadminhaz.yenombackend.dto;

import com.muhammadminhaz.yenombackend.model.TransactionSuggestion;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class SuggestionResponse {
    private String id;
    private String source;
    private String rawMessage;
    private BigDecimal amount;
    private String currency;
    private LocalDate transactionDate;
    private String description;
    private String category;
    private String type;
    private Boolean isHaram;
    private String haramReason;
    private BigDecimal aiConfidence;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;

    public static SuggestionResponse from(TransactionSuggestion s) {
        return SuggestionResponse.builder()
                .id(s.getId().toString())
                .source(s.getSource())
                .rawMessage(s.getRawMessage())
                .amount(s.getAmount())
                .currency(s.getCurrency())
                .transactionDate(s.getTransactionDate())
                .description(s.getDescription())
                .category(s.getCategory())
                .type(s.getType())
                .isHaram(s.getIsHaram())
                .haramReason(s.getHaramReason())
                .aiConfidence(s.getAiConfidence())
                .status(s.getStatus())
                .createdAt(s.getCreatedAt())
                .expiresAt(s.getExpiresAt())
                .build();
    }
}
