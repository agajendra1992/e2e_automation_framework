package com.company.framework.models.request;

import com.fasterxml.jackson.annotation.JsonProperty;

public class TokenAuthentication {
    @JsonProperty("username")
    private String username;

    @JsonProperty("password")
    private String password;

    public TokenAuthentication(String username, String password){
        this.username = username;
        this.password = password;
    }

    public void setUserName(String username){
        this.username = username;
    }

    public void setPassword(String password){
        this.password = password;
    }

    @JsonProperty("username")
    public String getUserName(){
        return username;
    }

    @JsonProperty("password")
    public String getPassword(){
        return password;
    }
}