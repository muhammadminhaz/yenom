package com.muhammadminhaz.yenombackend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SmsParseRequest {

    @NotBlank(message = "SMS text must not be blank")
    private String text;
}
