package com.company.tests.base;

import org.testng.Assert;
import org.testng.annotations.BeforeMethod;

import com.company.framework.api.client.ApiClient;
import com.company.framework.config.ConfigManager;
import com.company.framework.models.request.TokenAuthentication;

import io.restassured.response.Response;

public class APIBaseTest {
    protected final ApiClient client = new ApiClient();
    protected String token;
    protected Response response;

    @BeforeMethod
    public void setupAuth() {
        TokenAuthentication credentials = new TokenAuthentication(
                ConfigManager.get("api.username"), ConfigManager.get("api.password"));
        response = client.post("auth", credentials);
        Assert.assertEquals(response.getStatusCode(), 200);
        token = response.jsonPath().getString("token");
    }
}
