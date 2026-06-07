package com.muhammadminhaz.yenombackend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Kafka payload sent to the suggestion-parsing topic.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RawMessageEvent {
    private String userId;
    private String source; // GMAIL | SMS
    private String rawMessage;
}
