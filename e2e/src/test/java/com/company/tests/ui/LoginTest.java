package com.company.tests.ui;

import org.openqa.selenium.WebDriver;
import org.testng.annotations.Test;

import com.company.framework.config.ConfigManager;
import com.company.framework.ui.actions.LoginActions;

public class LoginTest extends LoginActions {

  public LoginTest(WebDriver driver) {
        super(driver);
    }

    @Test
    public void login() {
        clickOnLoginButton();
        loginCredentials("test@test.com", "Asd@1234");
       // loginCredentials(ConfigManager.get("username"), ConfigManager.get("password"));
        submitLogin();
    }

}
