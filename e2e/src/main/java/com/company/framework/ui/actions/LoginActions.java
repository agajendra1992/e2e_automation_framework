package com.company.framework.ui.actions;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

import com.company.framework.ui.pages.LoginPage;
import com.company.framework.ui.pages.UIBaseUtils;

public class LoginActions extends UIBaseUtils {

    LoginActions(WebDriver driver, WebDriverWait wait, Actions actions, Select select, WebElement element) {
        super(driver, wait, actions, select, element);
    }

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
