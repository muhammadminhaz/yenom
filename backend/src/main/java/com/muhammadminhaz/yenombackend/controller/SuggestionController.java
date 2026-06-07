package com.muhammadminhaz.yenombackend.controller;

import com.muhammadminhaz.yenombackend.dto.RawMessageEvent;
import com.muhammadminhaz.yenombackend.dto.SmsParseRequest;
import com.muhammadminhaz.yenombackend.dto.SuggestionResponse;
import com.muhammadminhaz.yenombackend.kafka.SuggestionParsingProducer;
import com.muhammadminhaz.yenombackend.service.AuthService;
import com.muhammadminhaz.yenombackend.service.SuggestionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/suggestions")
@RequiredArgsConstructor
public class SuggestionController {

    private final SuggestionService suggestionService;
    private final SuggestionParsingProducer producer;
    private final AuthService authService;

    /** Returns paginated PENDING suggestions for the current user. */
    @GetMapping
    public ResponseEntity<List<SuggestionResponse>> getPending(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = authService.getUser().getId();
        log.debug("getPending: userId={} page={} size={}", userId, page, size);
        List<SuggestionResponse> suggestions = suggestionService.getPendingSuggestions(userId, page, size);
        return ResponseEntity.ok(suggestions);
    }

    /** Accepts a suggestion and creates a real Transaction. */
    @PatchMapping("/{id}/accept")
    public ResponseEntity<SuggestionResponse> accept(@PathVariable UUID id) {
        UUID userId = authService.getUser().getId();
        log.info("accept: suggestionId={} userId={}", id, userId);
        SuggestionResponse response = suggestionService.acceptSuggestion(id, userId);
        return ResponseEntity.ok(response);
    }

    /** Rejects a suggestion (hides it from the list). */
    @PatchMapping("/{id}/reject")
    public ResponseEntity<SuggestionResponse> reject(@PathVariable UUID id) {
        UUID userId = authService.getUser().getId();
        log.info("reject: suggestionId={} userId={}", id, userId);
        SuggestionResponse response = suggestionService.rejectSuggestion(id, userId);
        return ResponseEntity.ok(response);
    }

    /** Hard-deletes a suggestion. */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> delete(@PathVariable UUID id) {
        UUID userId = authService.getUser().getId();
        log.info("delete: suggestionId={} userId={}", id, userId);
        suggestionService.deleteSuggestion(id, userId);
        return ResponseEntity.ok(Map.of("message", "Suggestion deleted"));
    }

    /**
     * Receives raw SMS text from the Android app (or iOS Shortcut) and
     * enqueues it for Claude parsing via Kafka.
     */
    @PostMapping("/sms")
    public ResponseEntity<Map<String, String>> submitSms(@Valid @RequestBody SmsParseRequest request) {
        UUID userId = authService.getUser().getId();
        log.info("submitSms: userId={} textLength={}", userId, request.getText().length());
        producer.send(new RawMessageEvent(userId.toString(), "SMS", request.getText()));
        return ResponseEntity.accepted().body(Map.of("message", "SMS queued for processing"));
    }
}
