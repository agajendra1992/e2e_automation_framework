package com.company.framework.api.client;

<<<<<<< HEAD
import static io.restassured.RestAssured.given;
=======
import io.restassured.response.Response;


import static io.restassured.RestAssured.*;

>>>>>>> origin/master

import com.company.framework.api.specifications.RequestSpec;
import com.company.framework.api.specifications.ResponseSpec;

<<<<<<< HEAD
import io.restassured.response.Response;

public class ApiClient {

    public Response get(String uri) {
        return given()
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
=======
public class ApiClient {

    protected void AppClient() {

    }

    public Response get(String uri) {
        return given()
                 .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
>>>>>>> origin/master
                .when()
                .get(uri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
<<<<<<< HEAD
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
=======
                .extract().response();
                
    }

    public Response post(String url, String uri, Object requestBody) {
        return given()
                .baseUri(uri)
                .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
>>>>>>> origin/master
                .body(requestBody)
                .when()
                .post(url)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
<<<<<<< HEAD
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
=======

>>>>>>> origin/master
    }
}
