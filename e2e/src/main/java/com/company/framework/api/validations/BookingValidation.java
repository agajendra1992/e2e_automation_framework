package com.company.framework.api.validations;

import org.testng.Assert;

import com.company.framework.models.request.BookingRequest;
import com.company.framework.models.response.BookingResponse;

public class BookingValidation {

    private BookingValidation() {
    }

    public static void validateBookingResponse(BookingResponse actualResponse,
            BookingRequest expectedRequest, int expectedBookingId) {
        Assert.assertEquals(actualResponse.getBookingId(), expectedBookingId,
                "Booking ID does not match");
        Assert.assertEquals(actualResponse.getFirstname(), expectedRequest.getFirstname(),
                "First name does not match");
        Assert.assertEquals(actualResponse.getLastname(), expectedRequest.getLastname(),
                "Last name does not match");
        Assert.assertEquals(actualResponse.getTotalprice(), expectedRequest.getTotalprice(),
                "Total price does not match");
        Assert.assertEquals(actualResponse.isDepositpaid(), expectedRequest.isDepositpaid(),
                "Deposit paid flag does not match");
        Assert.assertNotNull(actualResponse.getBookingdates(),
                "Booking dates are missing from the response");
        Assert.assertEquals(actualResponse.getBookingdates().getCheckin(),
                expectedRequest.getBookingdates().getCheckin(),
                "Check-in date does not match");
        Assert.assertEquals(actualResponse.getBookingdates().getCheckout(),
                expectedRequest.getBookingdates().getCheckout(),
                "Check-out date does not match");
        Assert.assertEquals(actualResponse.getAdditionalneeds(), expectedRequest.getAdditionalneeds(),
                "Additional needs do not match");
    }
}
