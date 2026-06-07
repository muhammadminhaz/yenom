package com.muhammadminhaz.yenombackend.service;

import com.muhammadminhaz.yenombackend.dto.SuggestionResponse;
import com.muhammadminhaz.yenombackend.exception.ResourceNotFoundException;
import com.muhammadminhaz.yenombackend.model.Transaction;
import com.muhammadminhaz.yenombackend.model.TransactionStatus;
import com.muhammadminhaz.yenombackend.model.TransactionSuggestion;
import com.muhammadminhaz.yenombackend.model.TransactionType;
import com.muhammadminhaz.yenombackend.repository.TransactionRepository;
import com.muhammadminhaz.yenombackend.repository.TransactionSuggestionRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class SuggestionService {

    private final TransactionSuggestionRepository suggestionRepository;
    private final TransactionRepository transactionRepository;

    // ── Read ──────────────────────────────────────────────────────────────────

    @Cacheable(value = "suggestions", key = "#userId + '_' + #page + '_' + #size")
    public List<SuggestionResponse> getPendingSuggestions(UUID userId, int page, int size) {
        log.debug("getPendingSuggestions: userId={} page={} size={}", userId, page, size);
        Page<TransactionSuggestion> result = suggestionRepository
                .findByUserIdAndStatusOrderByCreatedAtDesc(userId, "PENDING", PageRequest.of(page, size));
        return result.stream().map(SuggestionResponse::from).toList();
    }

    // ── Accept → creates a real Transaction ───────────────────────────────────

    @Transactional
    @CacheEvict(value = {"suggestions", "transactions"}, allEntries = true)
    public SuggestionResponse acceptSuggestion(UUID suggestionId, UUID userId) {
        TransactionSuggestion suggestion = findAndValidate(suggestionId, userId);

        // Create a real transaction from the suggestion
        Transaction tx = Transaction.builder()
                .userId(userId)
                .amount(suggestion.getAmount())
                .currency(suggestion.getCurrency() != null ? suggestion.getCurrency() : "USD")
                .transactionDate(suggestion.getTransactionDate() != null
                        ? suggestion.getTransactionDate() : java.time.LocalDate.now())
                .description(suggestion.getDescription() != null
                        ? suggestion.getDescription() : "Auto-imported transaction")
                .category(suggestion.getCategory())
                .type(parseType(suggestion.getType()))
                .status(TransactionStatus.COMPLETED)
                .build();

        transactionRepository.save(tx);
        log.info("Transaction created from suggestion: suggestionId={} txId={}", suggestionId, tx.getId());

        suggestion.setStatus("ACCEPTED");
        suggestionRepository.save(suggestion);
        log.info("Suggestion accepted: id={}", suggestionId);

        return SuggestionResponse.from(suggestion);
    }

    // ── Reject ────────────────────────────────────────────────────────────────

    @Transactional
    @CacheEvict(value = "suggestions", allEntries = true)
    public SuggestionResponse rejectSuggestion(UUID suggestionId, UUID userId) {
        TransactionSuggestion suggestion = findAndValidate(suggestionId, userId);
        suggestion.setStatus("REJECTED");
        suggestionRepository.save(suggestion);
        log.info("Suggestion rejected: id={}", suggestionId);
        return SuggestionResponse.from(suggestion);
    }

    // ── Delete ────────────────────────────────────────────────────────────────

    @Transactional
    @CacheEvict(value = "suggestions", allEntries = true)
    public void deleteSuggestion(UUID suggestionId, UUID userId) {
        TransactionSuggestion suggestion = findAndValidate(suggestionId, userId);
        suggestionRepository.delete(suggestion);
        log.info("Suggestion deleted: id={}", suggestionId);
    }

    // ── Internal ──────────────────────────────────────────────────────────────

    private TransactionSuggestion findAndValidate(UUID suggestionId, UUID userId) {
        TransactionSuggestion suggestion = suggestionRepository.findById(suggestionId)
                .orElseThrow(() -> new ResourceNotFoundException("Suggestion not found: " + suggestionId));

        if (!suggestion.getUserId().equals(userId)) {
            log.warn("Unauthorized access: suggestionId={} requestedBy={}", suggestionId, userId);
            throw new RuntimeException("You are not authorized to modify this suggestion");
        }
        return suggestion;
    }

    private TransactionType parseType(String type) {
        if ("INCOME".equalsIgnoreCase(type)) return TransactionType.INCOME;
        return TransactionType.EXPENSE;
    }
}
