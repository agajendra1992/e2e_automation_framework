// package com.company.tests.base;

// import org.checkerframework.checker.units.qual.A;
// import org.testng.Assert;
// import org.testng.annotations.BeforeMethod;

// import com.company.framework.api.client.ApiClient;
// import com.company.framework.config.ConfigManager;
// import com.company.framework.models.request.TokenAuthentication;

// import io.restassured.response.Response;

// public class APIBaseTest {
//     public ApiClient client = new ApiClient();
//     public static  String token = "";
//     public Response response;
    
//     @BeforeMethod
//     public void setupAuth() {

//         TokenAuthentication tokenAuthentication = new 
//         TokenAuthentication(ConfigManager.get("api.username"), ConfigManager.get("api.password")) ;
//         response  = client.post("auth", tokenAuthentication);
//         Assert.assertEquals(response.getStatusCode(), 200);
//         token = response.jsonPath().getString("token");


//     }

// }
