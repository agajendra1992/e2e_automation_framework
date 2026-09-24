package com.company.framework.api.client;

import static io.restassured.RestAssured.given;

import com.company.framework.api.specifications.RequestSpec;
import com.company.framework.api.specifications.ResponseSpec;

import io.restassured.response.Response;

public class ApiClient {

    public Response get(String uri) {
        return given()
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
                .when()
                .get(uri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
    }

    public Response get(String uri, String pathParam) {
        return given()
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
                .pathParam("id", pathParam)
                .when()
                .get(uri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
    }

    public Response post(String uri, Object requestBody) {
        return given()
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
                .body(requestBody)
                .when()
                .post(uri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
    }

    public Response post(String url, String baseUri, Object requestBody) {
        return given()
                .baseUri(baseUri)
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
                .body(requestBody)
                .when()
                .post(url)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
    }

    public Response post(String uri, String pathParam, Object requestBody) {
        return given()
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
                .pathParam("id", pathParam)
                .body(requestBody)
                .when()
                .post(uri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
    }
}
