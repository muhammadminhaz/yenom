package com.muhammadminhaz.yenombackend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.muhammadminhaz.yenombackend.dto.ParsedTransactionDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class GeminiParsingService {

    private static final String SYSTEM_PROMPT = """
            You are a financial transaction parser for an Islamic money manager app.
            Extract transaction details from financial messages (bank SMS, email notifications, payment confirmations).

            Islamic categories: Sadaqah (voluntary charity), Zakat (obligatory charity), Fitrana (Eid charity).
            Regular expense categories: Food & Dining, Transport, Shopping, Bills & Utilities, Healthcare,
              Education, Entertainment, Housing, Fitness, Travel, Gifts, Other.
            Income categories: Salary, Freelance, Business, Investment, Rental, Other Income.

            Flag isHaram=true with a reason for:
            - Alcohol, wine, beer, liquor purchases
            - Gambling, casino, lottery, betting
            - Pork or non-halal meat products (when clearly stated)
            - Adult entertainment or explicit content

            Set isFinancialMessage=false and aiConfidence=0 if the message is NOT a financial transaction.
            Set aiConfidence between 0.0 and 1.0 to reflect how certain you are.
            """;

    private final RestClient restClient;
    private final ObjectMapper objectMapper;
    private final String apiKey;

    @Value("${gemini.model}")
    private String model;

    public GeminiParsingService(
            @Value("${gemini.api-key}") String apiKey,
            @Value("${gemini.base-url}") String baseUrl,
            ObjectMapper objectMapper) {
        this.apiKey = apiKey;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    public ParsedTransactionDTO parse(String rawMessage) {
        if (rawMessage == null || rawMessage.isBlank()) {
            log.warn("parse: empty message, skipping");
            return null;
        }

        log.debug("GeminiParsingService.parse: length={}", rawMessage.length());

        try {
            Map<String, Object> requestBody = buildRequest(rawMessage);
            String responseJson = restClient.post()
                    .uri("/v1beta/models/{model}:generateContent?key={key}", model, apiKey)
                    .body(requestBody)
                    .retrieve()
                    .body(String.class);

            return parseResponse(responseJson);
        } catch (Exception e) {
            log.error("GeminiParsingService.parse error: {}", e.getMessage(), e);
            return null;
        }
    }

    private Map<String, Object> buildRequest(String message) {
        Map<String, Object> parameters = Map.of(
                "type", "OBJECT",
                "properties", Map.of(
                        "isFinancialMessage", Map.of("type", "BOOLEAN",
                                "description", "True if this message describes a real financial transaction"),
                        "amount", Map.of("type", "NUMBER", "description", "Transaction amount (positive number)"),
                        "currency", Map.of("type", "STRING", "description", "ISO-4217 currency code, e.g. USD, BDT, GBP"),
                        "transactionDate", Map.of("type", "STRING", "description", "Date in YYYY-MM-DD format"),
                        "description", Map.of("type", "STRING", "description", "Short merchant/purpose description (max 80 chars)"),
                        "category", Map.of("type", "STRING", "description", "Category from the allowed list"),
                        "type", Map.of("type", "STRING", "enum", List.of("INCOME", "EXPENSE")),
                        "isHaram", Map.of("type", "BOOLEAN", "description", "True if the purchase is Islamically impermissible"),
                        "haramReason", Map.of("type", "STRING", "description", "Reason it is haram, if isHaram is true"),
                        "aiConfidence", Map.of("type", "NUMBER", "description", "Confidence 0.0-1.0")
                ),
                "required", List.of("isFinancialMessage", "aiConfidence")
        );

        Map<String, Object> functionDeclaration = Map.of(
                "name", "extract_transaction",
                "description", "Extract financial transaction details from the given message",
                "parameters", parameters
        );

        return Map.of(
                "system_instruction", Map.of("parts", List.of(Map.of("text", SYSTEM_PROMPT))),
                "contents", List.of(Map.of(
                        "role", "user",
                        "parts", List.of(Map.of("text", message))
                )),
                "tools", List.of(Map.of("functionDeclarations", List.of(functionDeclaration))),
                "tool_config", Map.of("function_calling_config", Map.of("mode", "ANY"))
        );
    }

    private ParsedTransactionDTO parseResponse(String responseJson) throws Exception {
        JsonNode root = objectMapper.readTree(responseJson);

        // Gemini: candidates[0].content.parts[0].functionCall.args
        JsonNode candidates = root.path("candidates");
        if (!candidates.isArray() || candidates.isEmpty()) {
            log.warn("Gemini returned no candidates");
            return null;
        }

        JsonNode parts = candidates.get(0).path("content").path("parts");
        if (!parts.isArray() || parts.isEmpty()) {
            log.warn("Gemini candidate has no parts");
            return null;
        }

        JsonNode functionCall = null;
        for (JsonNode part : parts) {
            if (part.has("functionCall")) {
                functionCall = part.path("functionCall");
                break;
            }
        }

        if (functionCall == null) {
            log.warn("Gemini did not call extract_transaction");
            return null;
        }

        JsonNode args = functionCall.path("args");
        log.debug("Gemini function args: {}", args);

        boolean isFinancial = args.path("isFinancialMessage").asBoolean(false);
        double confidence = args.path("aiConfidence").asDouble(0.0);

        if (!isFinancial || confidence < 0.5) {
            log.info("Message rejected: isFinancial={} confidence={}", isFinancial, confidence);
            return null;
        }

        ParsedTransactionDTO dto = new ParsedTransactionDTO();
        dto.setFinancialMessage(true);
        dto.setAiConfidence(confidence);

        if (args.hasNonNull("amount")) {
            dto.setAmount(BigDecimal.valueOf(args.path("amount").asDouble()));
        }
        dto.setCurrency(args.path("currency").asText(null));
        dto.setTransactionDate(args.path("transactionDate").asText(null));
        dto.setDescription(args.path("description").asText(null));
        dto.setCategory(args.path("category").asText(null));
        dto.setType(args.path("type").asText(null));
        dto.setHaram(args.path("isHaram").asBoolean(false));
        dto.setHaramReason(args.path("haramReason").asText(null));

        log.info("Gemini parsed: amount={} currency={} desc='{}' confidence={}",
                dto.getAmount(), dto.getCurrency(), dto.getDescription(), confidence);
        return dto;
    }
}
