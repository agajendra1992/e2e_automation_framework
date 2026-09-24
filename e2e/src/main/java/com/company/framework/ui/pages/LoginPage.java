package com.company.framework.ui.pages;

import org.openqa.selenium.By;

public class LoginPage {

    private static final String loginButtonSelector = "//input[@id='login-button' or @name='login-button']";
    private static final String emailIdSelector = "//input[@id='user-name' or @name='user-name']";
    private static final String passwordIdSelector = "//input[@id='password' or @name='password']";
    private static final String submitSelector = "//input[@id='login-button' or @name='login-button']";

    public By clickLoginElement() {
        return By.xpath(loginButtonSelector);
    }

    public By setEmailElement() {
        return By.xpath(emailIdSelector);
    }

    public By setPasswordElement() {
        return By.xpath(passwordIdSelector);
    }

    public By submitElement() {
        return By.xpath(submitSelector);
    }

}
