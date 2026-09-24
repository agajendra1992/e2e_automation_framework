package com.company.framework.ui.pages;

<<<<<<< HEAD
public class HomePage {
    
=======
import org.openqa.selenium.By;

public class HomePage {

private static final String homePageHeaderSelector = "//div[text()='Swag Labs']";

public By getHomePageHeader(){
    return By.xpath(homePageHeaderSelector);
}
>>>>>>> origin/master
}
