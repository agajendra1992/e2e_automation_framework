package com.company.framework.ui.driver;

import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.edge.EdgeOptions;
import org.openqa.selenium.firefox.FirefoxOptions;

public class BrowserOptions {

    BrowserOptions() {

    }

    public ChromeOptions chromeOptions(boolean headless) {
        ChromeOptions options = new ChromeOptions();
        if (headless) {
            options.addArguments("--headless=new");
        }
        
     options.addArguments("--no-sandbox"); 
     options.addArguments("--disable-dev-shm-usage");
     options.addArguments("--disable-gpu"); 
     options.addArguments("--disable-software-rasterizer"); 
     options.addArguments("--disable-extensions");
     options.addArguments("--window-size=1920,1080");
     options.addArguments("--disable-notifications");
     options.addArguments("--user-data-dir=/tmp/jenkins-chrome");
        return options;
    }

    public FirefoxOptions firefoxOptions(boolean headless) {
        FirefoxOptions options = new FirefoxOptions();
        if (headless) {
            options.addArguments("--headless=new");
        }

        return options;
    }

    public EdgeOptions edgeOptions(boolean headless) {
        EdgeOptions options = new EdgeOptions();
        if (headless) {
            options.addArguments("--headless=new");
        }
        options.addArguments("--start-maximized");
        options.addArguments("--disable-notifications");
        return options;
    }

}