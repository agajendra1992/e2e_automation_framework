package com.company.tests.api;

import org.testng.Assert;
import org.testng.annotations.Test;

import com.company.framework.api.client.ApiClient;

import io.restassured.response.Response;

public class GetUserTest {
    private final ApiClient client = new ApiClient();

    @Test
    public void getProductList() {
        Response response = client.get("productsList");
        Assert.assertEquals(response.getStatusCode(), 200);
    }

    @Test
    public void getBrandList() {
        Response response = client.get("brandsList");
        Assert.assertEquals(response.getStatusCode(), 200);
    }
}
