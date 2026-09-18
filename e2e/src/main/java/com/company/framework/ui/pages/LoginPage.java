package com.company.framework.ui.pages;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

public class LoginPage extends UIBaseUtils {

    LoginPage(WebDriver driver, WebDriverWait wait, Actions actions, Select select, WebElement element) {
        super(driver, wait, actions, select, element);
    }
    
}
