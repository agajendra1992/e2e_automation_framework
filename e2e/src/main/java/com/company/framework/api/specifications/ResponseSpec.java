package com.company.framework.api.specifications;

import io.restassured.builder.ResponseSpecBuilder;

public class ResponseSpec {

    private  ResponseSpec(){

    }


    public static  io.restassured.specification.ResponseSpecification getResponseSpecification(){
        return new ResponseSpecBuilder().build();
    }
    
}
