package com.muhammadminhaz.yenombackend.kafka;

import com.muhammadminhaz.yenombackend.dto.ParsedTransactionDTO;
import com.muhammadminhaz.yenombackend.dto.RawMessageEvent;
import com.muhammadminhaz.yenombackend.model.TransactionSuggestion;
import com.muhammadminhaz.yenombackend.repository.TransactionSuggestionRepository;
import com.muhammadminhaz.yenombackend.service.GeminiParsingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class SuggestionParsingConsumer {

    private final GeminiParsingService geminiParsingService;
    private final TransactionSuggestionRepository suggestionRepository;

    @KafkaListener(
            topics = "${kafka.topic.suggestion-requests}",
            groupId = "${spring.kafka.consumer.group-id}",
            containerFactory = "kafkaListenerContainerFactory"
    )
    public void consume(RawMessageEvent event) {
        log.info("Kafka consume: userId={} source={}", event.getUserId(), event.getSource());

        try {
            ParsedTransactionDTO parsed = geminiParsingService.parse(event.getRawMessage());

            if (parsed == null) {
                log.info("Claude returned null for userId={}, skipping save", event.getUserId());
                return;
            }

            TransactionSuggestion suggestion = TransactionSuggestion.builder()
                    .userId(UUID.fromString(event.getUserId()))
                    .source(event.getSource())
                    .rawMessage(event.getRawMessage())
                    .amount(parsed.getAmount())
                    .currency(parsed.getCurrency())
                    .transactionDate(parseDate(parsed.getTransactionDate()))
                    .description(parsed.getDescription())
                    .category(parsed.getCategory())
                    .type(parsed.getType())
                    .isHaram(parsed.isHaram())
                    .haramReason(parsed.getHaramReason())
                    .aiConfidence(new java.math.BigDecimal(String.valueOf(parsed.getAiConfidence())))
                    .status("PENDING")
                    .build();

            suggestionRepository.save(suggestion);
            log.info("Suggestion saved: id={} userId={}", suggestion.getId(), event.getUserId());

        } catch (Exception e) {
            log.error("Consumer error for userId={}: {}", event.getUserId(), e.getMessage(), e);
        }
    }

    private LocalDate parseDate(String dateStr) {
        if (dateStr == null || dateStr.isBlank()) return LocalDate.now();
        try {
            return LocalDate.parse(dateStr);
        } catch (Exception e) {
            log.warn("Could not parse date '{}', defaulting to today", dateStr);
            return LocalDate.now();
        }
    }
}
