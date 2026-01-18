package com.muhammadminhaz.yenombackend.dto;

import com.muhammadminhaz.yenombackend.model.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateTransactionResponse {
    private String message;
    private BigDecimal amount;
    private TransactionType type;
}
