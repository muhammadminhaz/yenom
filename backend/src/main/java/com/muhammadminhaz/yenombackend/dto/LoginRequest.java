package com.muhammadminhaz.yenombackend.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Authentication request payload")
public class LoginRequest {

    @NotBlank
    @Size(min = 3, max = 30)
    @Schema(example = "john_doe")
    private String username;

    @NotBlank
    @Size(min = 4, max = 26)
    private String password;
}
