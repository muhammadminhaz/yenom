package com.muhammadminhaz.yenombackend.service;

import com.muhammadminhaz.yenombackend.dto.CreateTransactionRequest;
import com.muhammadminhaz.yenombackend.dto.CreateTransactionResponse;
import com.muhammadminhaz.yenombackend.model.Transaction;
import com.muhammadminhaz.yenombackend.model.TransactionStatus;
import com.muhammadminhaz.yenombackend.repository.TransactionRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

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
}
