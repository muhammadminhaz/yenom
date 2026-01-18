package com.muhammadminhaz.yenombackend.service;

import com.muhammadminhaz.yenombackend.dto.CreateTransactionRequest;
import com.muhammadminhaz.yenombackend.dto.CreateTransactionResponse;
import com.muhammadminhaz.yenombackend.dto.GetTransactionsResponse;
import com.muhammadminhaz.yenombackend.dto.TransactionsPageResponse;
import com.muhammadminhaz.yenombackend.model.Transaction;
import com.muhammadminhaz.yenombackend.model.TransactionStatus;
import com.muhammadminhaz.yenombackend.repository.TransactionRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
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
}
