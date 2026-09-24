package com.company.framework.ui.validations;


import com.company.framework.ui.pages.HomePage;

import com.company.framework.ui.pages.UIBaseUtils;
import org.openqa.selenium.WebDriver;


public class LoginValidation extends UIBaseUtils {

     public LoginValidation(WebDriver driver) {
        super(driver, null, null, null, null);
    }
    private HomePage homePage = new HomePage();

    public boolean verifyHomePageHeaderIsDisplayed(){
        return waitForVisiblity(homePage.getHomePageHeader()).isDisplayed();

    }
}
