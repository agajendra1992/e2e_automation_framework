package com.company.tests.base;

import org.testng.annotations.Test;

import com.company.framework.ui.driver.DriverManager;

public class DriverTest extends UIBaseTest {

    @Test
    public void launchBrowser() {
        String title = DriverManager.getDriver().getTitle();

        String currentUrl = DriverManager.getDriver().getCurrentUrl();

        System.out.println("Page Title : " + title);
        System.out.println("URL        : " + currentUrl);
    }
}
