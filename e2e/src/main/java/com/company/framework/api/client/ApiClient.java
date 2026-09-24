package com.company.framework.api.client;

import io.restassured.response.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


import static io.restassured.RestAssured.*;


import com.company.framework.api.specifications.RequestSpec;
import com.company.framework.api.specifications.ResponseSpec;
public class ApiClient {

        private static final Logger LOGGER = LoggerFactory.getLogger(ApiClient.class);

    protected void AppClient() {

    }

    public Response get(String uri) {
                LOGGER.info("GET {}", uri);
                Response response = given()
                 .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
                .when()
                .get(uri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
        LOGGER.info("GET {} -> {}", uri, response.getStatusCode());
        return response;
    }

    public Response get(String uri, String pathParam) {
        String resolvedUri = uri.contains("{id}") ? uri : uri + "/{id}";
        LOGGER.info("GET {} with id {}", uri, pathParam);
        Response response = given()
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
                .pathParam("id", pathParam)
                .when()
                .get(resolvedUri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
        LOGGER.info("GET {} -> {}", resolvedUri, response.getStatusCode());
        return response;
    }

    public Response post(String uri, Object requestBody) {
        LOGGER.info("POST {}", uri);
        Response response = given()
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
                .body(requestBody)
                .when()
                .post(uri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
        LOGGER.info("POST {} -> {}", uri, response.getStatusCode());
        return response;
    }

    public Response post(String uri, String pathParam, Object requestBody) {
        String resolvedUri = uri.contains("{id}") ? uri : uri + "/{id}";
        LOGGER.info("POST {} with id {}", uri, pathParam);
        Response response = given()
                .spec(RequestSpec.getRequestSpecification(
                        RequestSpec.headerMap("content-type", "application/json")))
                .pathParam("id", pathParam)
                .body(requestBody)
                .when()
                .post(resolvedUri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
        LOGGER.info("POST {} -> {}", resolvedUri, response.getStatusCode());
        return response;

    }

    public Response put(String uri, String pathParam, Object requestBody, String token) {
        String resolvedUri = uri.contains("{id}") ? uri : uri + "/{id}";
        LOGGER.info("PUT {} with id {}", uri, pathParam);
        Response response = given()
                .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
                .pathParam("id", pathParam)
                .cookie("token", token)
                .body(requestBody)
                .when()
                .put(resolvedUri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
        LOGGER.info("PUT {} -> {}", resolvedUri, response.getStatusCode());
        return response;
    }

    public Response delete(String uri, String pathParam, String token) {
        String resolvedUri = uri.contains("{id}") ? uri : uri + "/{id}";
        LOGGER.info("DELETE {} with id {}", uri, pathParam);
        Response response = given()
                .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
                .pathParam("id", pathParam)
                .cookie("token", token)
                .when()
                .delete(resolvedUri)
                .then()
                .spec(ResponseSpec.getResponseSpecification())
                .extract()
                .response();
        LOGGER.info("DELETE {} -> {}", resolvedUri, response.getStatusCode());
        return response;

    }
}
