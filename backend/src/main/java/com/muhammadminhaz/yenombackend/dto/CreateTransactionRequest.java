package com.muhammadminhaz.yenombackend.dto;

import com.muhammadminhaz.yenombackend.model.TransactionType;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateTransactionRequest {
    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    private BigDecimal amount;

    @NotBlank(message = "Currency is required")
    @Size(max = 3, message = "Currency must be up to 3 characters")
    private String currency;

    @NotNull(message = "Transaction date is required")
    @PastOrPresent(message = "Transaction date cannot be in the future")
    private LocalDate transactionDate;

    @NotBlank(message = "Description is required")
    @Size(max = 255, message = "Description must be up to 255 characters")
    private String description;

    @Size(max = 100, message = "Category must be up to 100 characters")
    private String category;

    @NotNull(message = "Transaction type is required")
    private TransactionType type;
}
