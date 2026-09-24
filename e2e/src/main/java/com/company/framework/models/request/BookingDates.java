package com.company.framework.models.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class BookingDates {
    @JsonProperty("checkin")
    private String checkin;

    @JsonProperty("checkout")
    private String checkout;

}
