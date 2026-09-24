package com.company.tests.base;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.company.framework.api.authentication.AuthManager;
import com.company.framework.api.authentication.TokenManager;
import com.company.framework.api.client.ApiClient;
import com.company.framework.api.services.BookingService;
import com.company.framework.config.ConfigManager;

import io.restassured.response.Response;

public class APIBaseTest {
    protected final ApiClient client = new ApiClient();
    protected final BookingService bookingService = new BookingService(client);
    protected String token;
    protected Response response;

    @BeforeMethod
    public void setupAuth() {
        token = new AuthManager().authenticate(
                ConfigManager.get("api.username"), ConfigManager.get("api.password"));
    }

    @AfterMethod(alwaysRun = true)
    public void clearAuth() {
        TokenManager.clear();
    }
}
