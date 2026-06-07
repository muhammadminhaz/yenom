package com.muhammadminhaz.yenombackend.controller;

import com.muhammadminhaz.yenombackend.service.AuthService;
import com.muhammadminhaz.yenombackend.service.GmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/gmail")
@RequiredArgsConstructor
public class GmailController {

    private final GmailService gmailService;
    private final AuthService authService;

    /** Returns the Google OAuth2 authorization URL. Frontend opens this in a browser. */
    @GetMapping("/auth-url")
    public ResponseEntity<Map<String, String>> getAuthUrl() {
        String userId = authService.getUser().getId().toString();
        log.info("getAuthUrl: userId={}", userId);
        String url = gmailService.buildAuthUrl(userId);
        return ResponseEntity.ok(Map.of("url", url));
    }

    /**
     * Google redirects here after user grants consent.
     * Exchanges the code for tokens and redirects back to the app deep-link.
     * This endpoint is public (no JWT required).
     */
    @GetMapping("/callback")
    public ResponseEntity<String> oauthCallback(
            @RequestParam String code,
            @RequestParam(required = false) String state) {
        log.info("Gmail OAuth callback: state(userId)={}", state);
        if (state == null || state.isBlank()) {
            return ResponseEntity.badRequest().body("Missing state parameter");
        }
        gmailService.exchangeCodeForTokens(code, state);
        // Return a simple HTML page that tells the user to return to the app
        String html = """
                <html><body style="font-family:sans-serif;text-align:center;padding:40px">
                  <h2>✓ Gmail connected successfully!</h2>
                  <p>You can close this tab and return to the Yenom app.</p>
                </body></html>
                """;
        return ResponseEntity.ok().header("Content-Type", "text/html").body(html);
    }

    /** Triggers a Gmail inbox fetch for the current user. */
    @PostMapping("/sync")
    public ResponseEntity<Map<String, Object>> syncInbox() {
        String userId = authService.getUser().getId().toString();
        log.info("Gmail sync triggered: userId={}", userId);
        int queued = gmailService.syncInbox(userId);
        return ResponseEntity.ok(Map.of(
                "message", "Gmail sync started",
                "messagesQueued", queued
        ));
    }

    /** Removes stored Gmail tokens. */
    @PostMapping("/disconnect")
    public ResponseEntity<Map<String, String>> disconnect() {
        String userId = authService.getUser().getId().toString();
        log.info("Gmail disconnect: userId={}", userId);
        gmailService.disconnect(userId);
        return ResponseEntity.ok(Map.of("message", "Gmail disconnected"));
    }

    /** Returns whether the current user has Gmail connected. */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Boolean>> status() {
        String userId = authService.getUser().getId().toString();
        boolean connected = gmailService.isConnected(userId);
        return ResponseEntity.ok(Map.of("connected", connected));
    }
}
