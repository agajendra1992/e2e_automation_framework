// package com.company.framework.api.client;
// public class ApiClient {
// <<<<<<< Updated upstream
    
// =======

//     protected void AppClient() {

//     }

//     public Response get(String uri) {
//         return given()
//                  .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
//                 .when()
//                 .get(uri)
//                 .then()
//                 .spec(ResponseSpec.getResponseSpecification())
//                 .extract().response();
//     }          
                
//     public Response get(String uri,String pathParam) {
//         return given()
//                  .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
//                  .param("id", pathParam)
//                 .when()
//                 .get(uri)
//                 .then()
//                 .spec(ResponseSpec.getResponseSpecification())
//                 .extract().response();
                
    
//     }

//     public Response post(String uri, Object requestBody) {
//         return given()
//                 .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
//                 .body(requestBody)
//                 .when()
//                 .post(uri)
//                 .then()
//                 .spec(ResponseSpec.getResponseSpecification())
//                 .extract()
//                 .response();

//     }

//     public Response post(String uri, String pathParam, Object requestBody) {
//         return given()
//                 .spec(RequestSpec.getRequestSpecification(RequestSpec.headerMap("content-type", "application/json")))
//                 .pathParam("id", pathParam)
//                 .body(requestBody)
//                 .when()
//                 .post(uri)
//                 .then()
//                 .spec(ResponseSpec.getResponseSpecification())
//                 .extract()
//                 .response();

//     }
// >>>>>>> Stashed changes
// }
