package com.company.framework.ui.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class LoginPage {

    private WebDriver driver;
    private static final String loginButtonSelector = "//a[text()='Log in']";
    private static final String emailIdSelector = "//input[@name='Email']";
    private static final String passwordIdSelector = "//input[@name='Password']";
    private static final String submitSelector = "//input[@name='Log in']";

    public LoginPage() {

    }

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
