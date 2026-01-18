package com.muhammadminhaz.yenombackend.service;

import com.muhammadminhaz.yenombackend.dto.LoginRequest;
import com.muhammadminhaz.yenombackend.dto.AuthResponse;
import com.muhammadminhaz.yenombackend.dto.ProfileResponse;
import com.muhammadminhaz.yenombackend.dto.RegisterRequest;
import com.muhammadminhaz.yenombackend.model.User;
import com.muhammadminhaz.yenombackend.repository.UserRepository;
import com.muhammadminhaz.yenombackend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthResponse register(RegisterRequest request) {

        if (userRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("Username already exists");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already registered");
        }

        User user = User.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .city(request.getCity())
                .country(request.getCountry())
                .continent(request.getContinent())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .username(request.getUsername())
                .build();

        userRepository.save(user);

        String accessToken = jwtUtil.generateAccessToken(
                String.valueOf(user.getId()),
                user.getRole()
        );

        String refreshToken = jwtUtil.generateRefreshToken(
                String.valueOf(user.getId())
        );

        return new AuthResponse(accessToken, refreshToken);
    }

    public AuthResponse login(LoginRequest request) {

        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Invalid credentials");
        }

        String accessToken = jwtUtil.generateAccessToken(
                String.valueOf(user.getId()),
                user.getRole()
        );

        String refreshToken = jwtUtil.generateRefreshToken(
                String.valueOf(user.getId())
        );

        return new AuthResponse(accessToken, refreshToken);
    }

    public ProfileResponse getCurrentUserProfile() {
        // Get the authenticated user
        User user = getUser();

        // Map to ProfileResponse DTO
        return ProfileResponse.builder()
                .username(user.getUsername())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .city(user.getCity())
                .country(user.getCountry())
                .continent(user.getContinent())
                .build();
    }

    public User getUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
