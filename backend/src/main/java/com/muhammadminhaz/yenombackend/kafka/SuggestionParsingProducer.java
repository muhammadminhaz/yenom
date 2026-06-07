package com.muhammadminhaz.yenombackend.kafka;

import com.muhammadminhaz.yenombackend.dto.RawMessageEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class SuggestionParsingProducer {

    private final KafkaTemplate<String, RawMessageEvent> kafkaTemplate;

    @Value("${kafka.topic.suggestion-requests}")
    private String topic;

    public void send(RawMessageEvent event) {
        log.info("Kafka send → topic={} userId={} source={}", topic, event.getUserId(), event.getSource());
        kafkaTemplate.send(topic, event.getUserId(), event)
                .whenComplete((result, ex) -> {
                    if (ex != null) {
                        log.error("Kafka send failed for userId={}: {}", event.getUserId(), ex.getMessage(), ex);
                    } else {
                        log.debug("Kafka send ok: offset={}", result.getRecordMetadata().offset());
                    }
                });
    }
}
