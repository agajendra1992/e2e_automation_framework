package com.company.framework.ui.actions;

import org.openqa.selenium.WebDriver;


import com.company.framework.ui.pages.LoginPage;
import com.company.framework.ui.pages.UIBaseUtils;

public class LoginActions extends UIBaseUtils {

    public LoginActions(WebDriver driver) {
        super(driver, null, null, null, null);
    }


    private LoginPage loginPage = new LoginPage();

    public void clickOnLoginButton() {
        waitForClickable(loginPage.clickLoginElement());
        click(loginPage.clickLoginElement());
    }

    public void loginCredentials(String username, String password) {
        waitForVisiblity(loginPage.setEmailElement());
        setText(loginPage.setEmailElement(), username);
        waitForVisiblity(loginPage.setPasswordElement());
        setText(loginPage.setPasswordElement(), password);
    }

    public void submitLogin() {
        waitForClickable(loginPage.submitElement());
        click(loginPage.submitElement());
    }

}
