package com.company.tests.ui;

import org.testng.annotations.Test;

import com.company.framework.config.ConfigManager;
import com.company.framework.ui.actions.LoginActions;
import com.company.framework.ui.driver.DriverManager;
import com.company.tests.base.UIBaseTest;

public class LoginTest extends UIBaseTest {

    @Test
    public void login() {
        LoginActions loginActions = new LoginActions(DriverManager.getDriver());
        loginActions.clickOnLoginButton();
        loginActions.loginCredentials(ConfigManager.get("username"), ConfigManager.get("password"));
        loginActions.submitLogin();
    }

}
