package com.company.tests.base;

import org.openqa.selenium.WebDriver;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.company.framework.config.ConfigManager;
import com.company.framework.ui.driver.DriverFactory;
import com.company.framework.ui.driver.DriverManager;

public class UIBaseTest {
    private DriverFactory driverFactory = new DriverFactory();
    @BeforeMethod (alwaysRun = true)
    public void setup(){
        WebDriver driver = driverFactory.createDriver();
        DriverManager.setDriver(driver);
        driver.manage().window().maximize();

        driver.get(ConfigManager.get("ui.base.url"));

    }
    @AfterMethod (alwaysRun = true)
    public void tearDown(){
        DriverManager.quitDriver();
        

    }

}
