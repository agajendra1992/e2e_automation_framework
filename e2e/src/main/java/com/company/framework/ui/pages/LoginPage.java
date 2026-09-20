package com.company.framework.ui.pages;

import org.openqa.selenium.By;

public class LoginPage {

    private static final String loginButtonSelector = "//a[text()='Log in']";
    private static final String emailIdSelector = "//input[@id='user-name']";
    private static final String passwordIdSelector = "//input[@id='password']";
    private static final String submitSelector = "//input[@id='login-button']";

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
