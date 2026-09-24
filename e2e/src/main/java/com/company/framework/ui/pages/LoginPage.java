package com.company.framework.ui.pages;

import org.openqa.selenium.By;

public class LoginPage {

    private static final String loginButtonSelector = "//a[contains(@class,'ico-login') or normalize-space(.)='Log in']";
    private static final String emailIdSelector = "//input[@id='Email' or @name='Email']";
    private static final String passwordIdSelector = "//input[@id='Password' or @name='Password']";
    private static final String submitSelector = "//button[contains(@class,'login-button') or @name='Log in']";

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
