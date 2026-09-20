package com.company.framework.ui.validations;

import com.aventstack.extentreports.util.Assert;
import com.company.framework.ui.pages.HomePage;
import com.company.framework.ui.pages.LoginPage;
import com.company.framework.ui.pages.UIBaseUtils;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

public class LoginValidation extends UIBaseUtils {

    public LoginValidation(WebDriver driver, WebDriverWait wait, Actions actions, Select select, WebElement element) {
        super(driver, null, null, null, null);
    }
    private HomePage homePage = new HomePage();

    public boolean verifyHomePageHeaderIsDisplayed(){
        return waitForVisiblity(homePage.getHomePageHeader()).isDisplayed();

    }
}
