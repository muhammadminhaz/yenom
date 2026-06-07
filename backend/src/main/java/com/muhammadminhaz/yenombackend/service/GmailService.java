package com.muhammadminhaz.yenombackend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.muhammadminhaz.yenombackend.kafka.SuggestionParsingProducer;
import com.muhammadminhaz.yenombackend.dto.RawMessageEvent;
import com.muhammadminhaz.yenombackend.model.GmailToken;
import com.muhammadminhaz.yenombackend.repository.GmailTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class GmailService {

    private static final String GMAIL_SCOPE = "https://www.googleapis.com/auth/gmail.readonly";
    private static final String AUTH_URL = "https://accounts.google.com/o/oauth2/auth";
    private static final String TOKEN_URL = "https://oauth2.googleapis.com/token";
    private static final String GMAIL_API = "https://gmail.googleapis.com/gmail/v1/users/me";

    // Financial keywords to filter inbox (reduces Claude calls on non-financial email)
    private static final String GMAIL_QUERY =
            "subject:(transaction OR payment OR debit OR credit OR receipt OR invoice OR transfer OR bill OR statement)";

    private final GmailTokenRepository gmailTokenRepository;
    private final SuggestionParsingProducer producer;
    private final ObjectMapper objectMapper;

    @Value("${google.client-id}")
    private String clientId;

    @Value("${google.client-secret}")
    private String clientSecret;

    @Value("${google.redirect-uri}")
    private String redirectUri;

    // ── Auth URL ─────────────────────────────────────────────────────────────

    public String buildAuthUrl(String userId) {
        String url = UriComponentsBuilder.fromUriString(AUTH_URL)
                .queryParam("client_id", clientId)
                .queryParam("redirect_uri", redirectUri)
                .queryParam("response_type", "code")
                .queryParam("scope", GMAIL_SCOPE)
                .queryParam("state", userId)
                .queryParam("access_type", "offline")
                .queryParam("prompt", "consent")
                .toUriString();
        log.info("Built Gmail auth URL for userId={}", userId);
        return url;
    }

    // ── Token exchange (called from OAuth callback) ───────────────────────────

    public void exchangeCodeForTokens(String code, String userId) {
        log.info("Exchanging Gmail auth code for userId={}", userId);

        RestClient client = RestClient.create();
        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("code", code);
        params.add("client_id", clientId);
        params.add("client_secret", clientSecret);
        params.add("redirect_uri", redirectUri);
        params.add("grant_type", "authorization_code");

        try {
            String responseJson = client.post()
                    .uri(TOKEN_URL)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(params)
                    .retrieve()
                    .body(String.class);

            JsonNode json = objectMapper.readTree(responseJson);
            String accessToken = json.path("access_token").asText();
            String refreshToken = json.path("refresh_token").asText();
            int expiresIn = json.path("expires_in").asInt(3600);

            GmailToken token = gmailTokenRepository.findByUserId(UUID.fromString(userId))
                    .orElseGet(() -> GmailToken.builder().userId(UUID.fromString(userId)).build());

            token.setAccessToken(accessToken);
            token.setRefreshToken(refreshToken);
            token.setTokenExpiry(LocalDateTime.now().plusSeconds(expiresIn - 60));

            // Fetch Gmail profile to get the email address
            try {
                String profileJson = makeGmailRequest(accessToken, "/profile");
                JsonNode profile = objectMapper.readTree(profileJson);
                token.setGmailEmail(profile.path("emailAddress").asText(null));
            } catch (Exception e) {
                log.warn("Could not fetch Gmail profile: {}", e.getMessage());
            }

            gmailTokenRepository.save(token);
            log.info("Gmail tokens saved for userId={} email={}", userId, token.getGmailEmail());

        } catch (Exception e) {
            log.error("Token exchange failed for userId={}: {}", userId, e.getMessage(), e);
            throw new RuntimeException("Failed to exchange Gmail auth code: " + e.getMessage());
        }
    }

    // ── Inbox sync ────────────────────────────────────────────────────────────

    public int syncInbox(String userId) {
        log.info("GmailService.syncInbox: userId={}", userId);

        GmailToken token = gmailTokenRepository.findByUserId(UUID.fromString(userId))
                .orElseThrow(() -> new RuntimeException("Gmail not connected for userId=" + userId));

        String accessToken = getValidAccessToken(token);

        try {
            // Fetch message list filtered by financial keywords
            String listJson = makeGmailRequest(accessToken,
                    "/messages?maxResults=20&q=" + java.net.URLEncoder.encode(GMAIL_QUERY, StandardCharsets.UTF_8));
            JsonNode listNode = objectMapper.readTree(listJson);
            JsonNode messages = listNode.path("messages");

            if (!messages.isArray() || messages.isEmpty()) {
                log.info("No matching Gmail messages found for userId={}", userId);
                return 0;
            }

            List<String> bodies = new ArrayList<>();
            for (JsonNode msg : messages) {
                String msgId = msg.path("id").asText();
                try {
                    String msgJson = makeGmailRequest(accessToken, "/messages/" + msgId + "?format=full");
                    String text = extractMessageText(msgJson);
                    if (text != null && !text.isBlank()) {
                        bodies.add(text);
                    }
                } catch (Exception e) {
                    log.warn("Failed to fetch Gmail message {}: {}", msgId, e.getMessage());
                }
            }

            // Publish each candidate to Kafka for Claude parsing
            for (String body : bodies) {
                producer.send(new RawMessageEvent(userId, "GMAIL", body));
            }

            log.info("GmailService.syncInbox: queued {} messages for userId={}", bodies.size(), userId);
            return bodies.size();

        } catch (Exception e) {
            log.error("Gmail sync error for userId={}: {}", userId, e.getMessage(), e);
            throw new RuntimeException("Gmail sync failed: " + e.getMessage());
        }
    }

    public void disconnect(String userId) {
        gmailTokenRepository.findByUserId(UUID.fromString(userId))
                .ifPresent(token -> {
                    gmailTokenRepository.delete(token);
                    log.info("Gmail tokens removed for userId={}", userId);
                });
    }

    public boolean isConnected(String userId) {
        return gmailTokenRepository.findByUserId(UUID.fromString(userId)).isPresent();
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    private String getValidAccessToken(GmailToken token) {
        if (token.getTokenExpiry() == null || LocalDateTime.now().isAfter(token.getTokenExpiry())) {
            log.info("Access token expired, refreshing for userId={}", token.getUserId());
            return refreshAccessToken(token);
        }
        return token.getAccessToken();
    }

    private String refreshAccessToken(GmailToken token) {
        RestClient client = RestClient.create();
        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("refresh_token", token.getRefreshToken());
        params.add("client_id", clientId);
        params.add("client_secret", clientSecret);
        params.add("grant_type", "refresh_token");

        try {
            String responseJson = client.post()
                    .uri(TOKEN_URL)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(params)
                    .retrieve()
                    .body(String.class);

            JsonNode json = objectMapper.readTree(responseJson);
            String newAccessToken = json.path("access_token").asText();
            int expiresIn = json.path("expires_in").asInt(3600);

            token.setAccessToken(newAccessToken);
            token.setTokenExpiry(LocalDateTime.now().plusSeconds(expiresIn - 60));
            gmailTokenRepository.save(token);

            log.info("Access token refreshed for userId={}", token.getUserId());
            return newAccessToken;
        } catch (Exception e) {
            log.error("Token refresh failed for userId={}: {}", token.getUserId(), e.getMessage(), e);
            throw new RuntimeException("Gmail token refresh failed: " + e.getMessage());
        }
    }

    private String makeGmailRequest(String accessToken, String path) {
        return RestClient.create()
                .get()
                .uri(GMAIL_API + path)
                .header("Authorization", "Bearer " + accessToken)
                .retrieve()
                .body(String.class);
    }

    private String extractMessageText(String messageJson) throws Exception {
        JsonNode msg = objectMapper.readTree(messageJson);

        // Try snippet first (short, clean summary)
        String snippet = msg.path("snippet").asText(null);
        if (snippet != null && !snippet.isBlank()) {
            return snippet;
        }

        // Fallback: decode body parts
        return decodePayload(msg.path("payload"));
    }

    private String decodePayload(JsonNode payload) {
        // Check direct body first
        String data = payload.path("body").path("data").asText(null);
        if (data != null && !data.isBlank()) {
            return decodeBase64Url(data);
        }

        // Walk multipart parts
        JsonNode parts = payload.path("parts");
        if (parts.isArray()) {
            for (JsonNode part : parts) {
                String mimeType = part.path("mimeType").asText("");
                if (mimeType.startsWith("text/plain")) {
                    String partData = part.path("body").path("data").asText(null);
                    if (partData != null) return decodeBase64Url(partData);
                }
            }
        }
        return null;
    }

    private String decodeBase64Url(String encoded) {
        try {
            byte[] bytes = Base64.getUrlDecoder().decode(encoded);
            String text = new String(bytes, StandardCharsets.UTF_8);
            // Trim to 500 chars to stay within token budget
            return text.length() > 500 ? text.substring(0, 500) : text;
        } catch (Exception e) {
            log.warn("Base64 decode error: {}", e.getMessage());
            return null;
        }
    }
}
