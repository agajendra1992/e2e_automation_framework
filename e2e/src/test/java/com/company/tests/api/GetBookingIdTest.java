package com.company.tests.api;

import org.testng.Assert;
import org.testng.annotations.Test;

import com.company.framework.models.request.BookingDates;
import com.company.framework.models.request.BookingRequest;
import com.company.tests.base.APIBaseTest;

import io.restassured.response.Response;

public class GetBookingIdTest extends APIBaseTest {

    @Test
    public void getBookingId() {
        BookingRequest bookingRequest = new BookingRequest(
                "Jim", "Brown", 111, true,
                new BookingDates("2026-01-01", "2026-01-05"), "Breakfast");

        Response createBookingResponse = bookingService.createBooking(bookingRequest);
        Assert.assertEquals(createBookingResponse.getStatusCode(), 200);

        int bookingId = createBookingResponse.jsonPath().getInt("bookingid");
        response = bookingService.getBooking(bookingId);
        Assert.assertEquals(response.getStatusCode(), 200);
    }

}
