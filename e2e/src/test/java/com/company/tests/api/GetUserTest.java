package com.company.tests.api;

import org.testng.Assert;
import org.testng.annotations.Test;

import com.company.framework.api.client.ApiClient;

<<<<<<< HEAD
import io.restassured.response.Response;

public class GetUserTest {
    private final ApiClient client = new ApiClient();

    @Test
    public void getProductList() {
        Response response = client.get("productsList");
        Assert.assertEquals(response.getStatusCode(), 200);
=======

import io.restassured.response.Response;

public class GetUserTest {
    private Response response;

    private ApiClient client = new ApiClient();

    @Test
    public void getProductList() {
        response = client.get("productsList");
        Assert.assertEquals(response.getStatusCode(), 200);

>>>>>>> origin/master
    }

    @Test
    public void getBrandList() {
<<<<<<< HEAD
        Response response = client.get("brandsList");
        Assert.assertEquals(response.getStatusCode(), 200);
    }
=======
        response = client.get("brandsList");
        Assert.assertEquals(response.getStatusCode(), 200);

    }

>>>>>>> origin/master
}
