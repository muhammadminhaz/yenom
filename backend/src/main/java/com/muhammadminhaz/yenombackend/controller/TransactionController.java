package com.muhammadminhaz.yenombackend.controller;

import com.muhammadminhaz.yenombackend.dto.CreateTransactionRequest;
import com.muhammadminhaz.yenombackend.dto.CreateTransactionResponse;
import com.muhammadminhaz.yenombackend.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;

    @Operation(summary = "Create a new transaction",
            description = "Creates a transaction for the authenticated user. The userId is derived from the JWT token, not passed in the request.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Transaction created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid input data"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "500", description = "Internal server error")
    })
    @PostMapping
    public ResponseEntity<CreateTransactionResponse> createTransaction(
            @Valid @RequestBody CreateTransactionRequest request) {
        CreateTransactionResponse response = transactionService.createTransaction(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    // Future endpoints can be added here, e.g., get transactions, update, delete, etc.
}
