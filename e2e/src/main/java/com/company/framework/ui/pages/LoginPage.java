package com.company.framework.ui.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

public class LoginPage{

    private WebDriver driver;
    private static final String username = "";
    private static final String loginButtonSelector ="//a[text()='Log in']";
    private static final String emailIdSelector ="//input[@name='Email']";
    private static final String passwordIdSelector ="//input[@name='Password']";
    private static final String submitSelector ="//input[@name='Log in']";

    private LoginPage(WebDriver driver){
        this.driver = driver;

    }

    public void clickLogin(WebElement element){

    }



    
    }
    
}
