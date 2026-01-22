package com.muhammadminhaz.yenombackend.service;

import com.muhammadminhaz.yenombackend.dto.*;
import com.muhammadminhaz.yenombackend.exception.ResourceNotFoundException;
import com.muhammadminhaz.yenombackend.model.Transaction;
import com.muhammadminhaz.yenombackend.model.TransactionStatus;
import com.muhammadminhaz.yenombackend.repository.TransactionRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TransactionService {
    private final AuthService authService;
    private final TransactionRepository transactionRepository;

    @Transactional
    @CacheEvict(value = "transactions", key = "#authService.getUser().getId() + '_*'", allEntries = true)
    public CreateTransactionResponse createTransaction(CreateTransactionRequest request) {
        Transaction transaction = Transaction.builder()
                .userId(authService.getUser().getId())
                .amount(request.getAmount())
                .currency(request.getCurrency())
                .transactionDate(request.getTransactionDate())
                .description(request.getDescription())
                .category(request.getCategory())
                .type(request.getType())
                .status(TransactionStatus.COMPLETED)
                .build();
        transactionRepository.save(transaction);
        CreateTransactionResponse response = new CreateTransactionResponse();
        response.setMessage("Transaction created successfully");
        response.setAmount(request.getAmount());
        response.setType(request.getType());
        return response;
    }

    @Cacheable(value = "transactions", key = "#userId + '_' + #page + '_' + #size")
    public TransactionsPageResponse getUserTransactions(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Transaction> transactions = transactionRepository.findByUserIdOrderByTransactionDateDesc(userId, pageable);

        List<GetTransactionsResponse> content = transactions.stream()
                .map(tx -> new GetTransactionsResponse(
                        tx.getId().toString(),
                        tx.getAmount(),
                        tx.getCurrency(),
                        tx.getTransactionDate(),
                        tx.getDescription(),
                        tx.getCategory(),
                        tx.getType(),
                        tx.getStatus()
                ))
                .toList();

        return new TransactionsPageResponse(
                transactions.getNumber(),
                transactions.getSize(),
                transactions.getTotalElements(),
                transactions.getTotalPages(),
                content
        );
    }

    @Transactional
    @CacheEvict(value = "transactions", allEntries = true)
    public UpdateTransactionResponse updateTransaction(UUID transactionId, UpdateTransactionRequest request) {
        UUID userId = authService.getUser().getId();
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found with id: " + transactionId));

        if (!transaction.getUserId().equals(userId)) {
            throw new RuntimeException("You are not authorized to update this transaction");
        }

        transaction.setAmount(request.getAmount());
        transaction.setCurrency(request.getCurrency());
        transaction.setTransactionDate(request.getTransactionDate());
        transaction.setDescription(request.getDescription());
        transaction.setCategory(request.getCategory());
        transaction.setType(request.getType());
        transaction.setStatus(request.getStatus());

        transactionRepository.save(transaction);

        return UpdateTransactionResponse.builder()
                .message("Transaction updated successfully")
                .id(transaction.getId())
                .amount(transaction.getAmount())
                .currency(transaction.getCurrency())
                .transactionDate(transaction.getTransactionDate())
                .description(transaction.getDescription())
                .category(transaction.getCategory())
                .type(transaction.getType())
                .status(transaction.getStatus())
                .build();
    }

    @Transactional
    @CacheEvict(value = "transactions", allEntries = true)
    public void deleteTransaction(UUID transactionId) {
        UUID userId = authService.getUser().getId();
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found with id: " + transactionId));

        if (!transaction.getUserId().equals(userId)) {
            throw new RuntimeException("You are not authorized to delete this transaction");
        }

        transactionRepository.delete(transaction);
    }
}
