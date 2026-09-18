package com.company.framework.ui.driver;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.edge.EdgeDriver;
import org.openqa.selenium.firefox.FirefoxDriver;
import com.company.framework.ui.driver.BrowserOptions;

import com.company.framework.config.ConfigManager;

import io.github.bonigarcia.wdm.WebDriverManager;

public class DriverFactory {

   private BrowserOptions options = new BrowserOptions();
    public WebDriver createDriver(){
        String browser = ConfigManager.get("browser").toLowerCase().trim();
        boolean headless = Boolean.parseBoolean(ConfigManager.get("headless"));

        return switch(browser){
            case "chrome" -> createChromeDriverSetup(headless);
            case "firefox"-> createFirefoxDriverSetup(headless);
            case "edge" -> createEdgeDriverSetup(headless);
            default -> throw new IllegalArgumentException
            ("Unsupported browser: " + browser);
        };


    }

    private  WebDriver createChromeDriverSetup(boolean headless) {
        WebDriverManager.chromedriver().setup();
        return new ChromeDriver(options.chromeOptions(headless));
    }

    private WebDriver createFirefoxDriverSetup(boolean headless) {
        WebDriverManager.firefoxdriver().setup();
        return new FirefoxDriver(options.firefoxOptions(headless));
    }

    private WebDriver createEdgeDriverSetup(boolean headless) {
        WebDriverManager.edgedriver().setup();
        return new EdgeDriver(options.edgeOptions(headless));
    }
}
