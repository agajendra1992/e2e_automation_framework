package com.company.framework.api.specifications;

import java.util.HashMap;
import java.util.Map;

import com.company.framework.config.ConfigManager;

import io.restassured.builder.RequestSpecBuilder;

public final class RequestSpec {

    private RequestSpec() {

    }

    public static io.restassured.specification.RequestSpecification getRequestSpecification(
            Map<String, String> headerMap) { 
            return new RequestSpecBuilder().setBaseUri(ConfigManager.get("api.base.url"))
                    .addHeaders(headerMap).build();
        
    }
<<<<<<< HEAD
    
=======
>>>>>>> origin/master

    public static Map<String, String> headerMap(String key, String value) {
        HashMap<String, String> headerHashMap = new HashMap<>();
        headerHashMap.put(key, value);
        return headerHashMap;
    }

}
