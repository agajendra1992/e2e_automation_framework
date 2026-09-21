package com.company.framework.api.client;

import io.restassured.response.Response;


import static io.restassured.RestAssured.*;


import com.company.framework.api.specifications.RequestSpec;
import com.company.framework.api.specifications.ResponseSpec;

public class ApiClient {

    protected void AppClient() {

    }

    public Response get(String uri) {
        return given()
                 .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
                .when()
                .get(uri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract().response();
                
    }

    public Response post(String url, String uri, Object requestBody) {
        return given()
                .baseUri(uri)
                .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
                .body(requestBody)
                .when()
                .post(url)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();

    }
}
