package com.company.framework.ui.pages;

import org.openqa.selenium.By;

public class HomePage {

private static final String homePageHeaderSelector = "//div[text()='Swag Labs']";

public By getHomePageHeader(){
    return By.xpath(homePageHeaderSelector);
}
}
