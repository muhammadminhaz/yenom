package com.muhammadminhaz.yenombackend.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Authentication response containing JWT tokens")
public class AuthResponse {

    @Schema(description = "Short-lived JWT access token")
    private String accessToken;

    @Schema(description = "Long-lived refresh token")
    private String refreshToken;
}

