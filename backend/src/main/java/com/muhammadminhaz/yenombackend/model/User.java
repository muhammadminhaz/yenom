package com.muhammadminhaz.yenombackend.model;

import com.fasterxml.uuid.Generators;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(
        name = "users",
        indexes = {
                @Index(name = "idx_users_username", columnList = "username")
        }
)
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class User {

    @Id
    @Column(columnDefinition = "uuid", updatable = false, nullable = false)
    private UUID id;

    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 30)
    @Column(nullable = false, unique = true, length = 30)
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    @Column(nullable = false, unique = true)
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8)
    @Column(nullable = false)
    private String password;

    @NotBlank
    @Column(nullable = false)
    private String role;

    // New fields
    @NotBlank(message = "First name is required")
    @Size(max = 50)
    @Column(nullable = false, length = 50)
    private String firstName;

    @NotBlank(message = "Last name is required")
    @Size(max = 50)
    @Column(nullable = false, length = 50)
    private String lastName;

    @Size(max = 100)
    @Column(length = 100)
    private String city;

    @Size(max = 100)
    @Column(length = 100)
    private String country;

    @Size(max = 100)
    @Column(length = 100)
    private String continent;

    @PrePersist
    public void prePersist() {
        if (this.id == null) {
            this.id = Generators.timeBasedGenerator().generate();
        }
        this.role = "USER";
    }
}
