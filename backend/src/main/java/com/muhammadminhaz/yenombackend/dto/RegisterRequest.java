package com.muhammadminhaz.yenombackend.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Register a new user")
public class RegisterRequest {

    @NotBlank
    @Size(min = 3, max = 30)
    @Schema(example = "muhammad_minhaz", description = "Unique username")
    private String username;

    @NotBlank
    @Email
    @Schema(example = "muhammad.minhaz@example.com", description = "Unique email for login")
    private String email;

    @NotBlank
    @Size(min = 6, max = 26)
    @Schema(example = "StrongPassword123", description = "User password")
    private String password;

    @NotBlank
    @Size(min = 2, max = 50)
    @Schema(example = "Muhammad", description = "First name of the user")
    private String firstName;

    @NotBlank
    @Size(min = 2, max = 50)
    @Schema(example = "Minhaz", description = "Last name of the user")
    private String lastName;

    @Schema(example = "New York", description = "User city (optional)")
    private String city;

    @Schema(example = "USA", description = "User country (optional)")
    private String country;

    @Schema(example = "North America", description = "User continent (optional)")
    private String continent;
}

