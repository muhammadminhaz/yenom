package com.muhammadminhaz.yenombackend.controller;

import com.muhammadminhaz.yenombackend.dto.CreateTransactionRequest;
import com.muhammadminhaz.yenombackend.dto.CreateTransactionResponse;
import com.muhammadminhaz.yenombackend.dto.GetTransactionsResponse;
import com.muhammadminhaz.yenombackend.dto.TransactionsPageResponse;
import com.muhammadminhaz.yenombackend.model.Transaction;
import com.muhammadminhaz.yenombackend.service.AuthService;
import com.muhammadminhaz.yenombackend.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;
    private final AuthService authService;

    @Operation(summary = "Create a new transaction",
            description = "Creates a transaction for the authenticated user. The userId is derived from the JWT token, not passed in the request.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Transaction created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid input data"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "500", description = "Internal server error")
    })
    @PostMapping("/create")
    public ResponseEntity<CreateTransactionResponse> createTransaction(
            @Valid @RequestBody CreateTransactionRequest request) {
        CreateTransactionResponse response = transactionService.createTransaction(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @Operation(summary = "Get all transactions",
            description = "Get a paginated list of all transactions for the authenticated user.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Transactions fetched successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid input data"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "500", description = "Internal server error")
    })

    @GetMapping
    public TransactionsPageResponse getTransactions(
            @Parameter(description = "Page number (starts from 0)")
            @RequestParam(defaultValue = "0") int page,

            @Parameter(description = "Number of transactions per page")
            @RequestParam(defaultValue = "10") int size
    ) {
        UUID userId = authService.getUser().getId();
        return transactionService.getUserTransactions(userId, page, size);
    }

}
