package com.muhammadminhaz.yenombackend.repository;

import com.muhammadminhaz.yenombackend.model.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {
    Page<Transaction> findByUserIdOrderByTransactionDateDesc(UUID userId, Pageable pageable);
}
