package com.company.framework.ui.actions;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

import com.company.framework.ui.pages.UIBaseUtils;

public class LoginActions extends UIBaseUtils{

    LoginActions(WebDriver driver, WebDriverWait wait, Actions actions, Select select, WebElement element) {
        super(driver, wait, actions, select, element);
    }
    
}
