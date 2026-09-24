package com.company.tests.api;

import org.testng.Assert;
import org.testng.annotations.Test;

import com.company.framework.models.request.BookingRequest;
import com.company.framework.models.response.BookingResponse;
import com.company.framework.api.validations.BookingValidation;
import com.company.framework.utils.JSONUtils;
import com.company.tests.base.APIBaseTest;

import io.restassured.response.Response;

public class GetBookingIdTest extends APIBaseTest {

    @Test(testName = "booking", description = "Verifies valid booking details")
    public void getBookingId() {
        BookingRequest bookingRequest = JSONUtils.fromResource(
            "testdata/booking-request.json", BookingRequest.class);

        Response createBookingResponse = bookingService.createBooking(bookingRequest);
        Assert.assertEquals(createBookingResponse.getStatusCode(), 200);

        int bookingId = createBookingResponse.jsonPath().getInt("bookingid");
        response = bookingService.getBooking(bookingId);
        Assert.assertEquals(response.getStatusCode(), 200);

        BookingResponse bookingResponse = JSONUtils.fromJson(
            response.asString(), BookingResponse.class);

        BookingValidation.validateBookingResponse(bookingResponse, bookingRequest);

        System.out.println("Validated booking response: " + JSONUtils.toJson(bookingResponse));
    }

}
