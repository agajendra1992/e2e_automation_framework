package com.company.framework.models.request;

public class TokenAuthentication {
    private String username;
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

    public String getUserName(){
        return username;
    }

    public String getPassword(){
        return password;
    }
}