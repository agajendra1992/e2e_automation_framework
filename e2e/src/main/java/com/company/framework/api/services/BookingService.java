package com.company.framework.api.services;

import com.company.framework.api.client.ApiClient;
import com.company.framework.models.request.BookingRequest;

import io.restassured.response.Response;

public class BookingService {
    private static final String BOOKING_RESOURCE = "booking";
    private final ApiClient client;

    public BookingService() {
        this(new ApiClient());
    }

    public BookingService(ApiClient client) {
        this.client = client;
    }

    public Response createBooking(BookingRequest request) {
        return client.post(BOOKING_RESOURCE, request);
    }

    public Response getBooking(int bookingId) {
        return client.get(BOOKING_RESOURCE, String.valueOf(bookingId));
    }

    public Response updateBooking(int bookingId, BookingRequest request, String token) {
        return client.put(BOOKING_RESOURCE, String.valueOf(bookingId), request, token);
    }

    public Response deleteBooking(int bookingId, String token) {
        return client.delete(BOOKING_RESOURCE, String.valueOf(bookingId), token);
    }
}
