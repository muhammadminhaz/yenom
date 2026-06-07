package com.muhammadminhaz.yenombackend.repository;

import com.muhammadminhaz.yenombackend.model.TransactionSuggestion;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.UUID;

public interface TransactionSuggestionRepository extends JpaRepository<TransactionSuggestion, UUID> {

    Page<TransactionSuggestion> findByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, String status, Pageable pageable);

    @Modifying
    @Query("DELETE FROM TransactionSuggestion s WHERE s.expiresAt < :now")
    int deleteExpired(LocalDateTime now);
}
