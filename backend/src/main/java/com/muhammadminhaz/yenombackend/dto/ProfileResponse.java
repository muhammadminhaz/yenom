package com.muhammadminhaz.yenombackend.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "Get User Profile")
public class ProfileResponse {
    @Schema(example = "muhammad_minhaz", description = "Unique username")
    private String username;

    @Schema(example = "muhammad.minhaz@example.com", description = "Unique email for login")
    private String email;

    @Schema(example = "Muhammad", description = "First name of the user")
    private String firstName;

    @Schema(example = "Minhaz", description = "Last name of the user")
    private String lastName;

    @Schema(example = "New York", description = "User city (optional)")
    private String city;

    @Schema(example = "USA", description = "User country (optional)")
    private String country;

    @Schema(example = "North America", description = "User continent (optional)")
    private String continent;
}
