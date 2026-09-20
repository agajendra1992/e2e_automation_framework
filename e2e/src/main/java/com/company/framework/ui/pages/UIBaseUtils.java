package com.company.framework.ui.pages;

import java.time.Duration;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

import com.company.framework.config.ConfigManager;
import com.company.framework.ui.driver.DriverManager;

public abstract class UIBaseUtils {

    public WebDriver driver;
    public WebDriverWait wait;
    public Actions actions;
    public Select select;
    public WebElement element;

    public UIBaseUtils(WebDriver driver, WebDriverWait wait, Actions actions, Select select, WebElement element) {
        this.element = element;
        this.driver = DriverManager.getDriver();
        this.wait = new WebDriverWait(driver,
                Duration.ofSeconds(Integer.parseInt(ConfigManager.get("ui.timeout"))));
        this.actions = new Actions(driver);
        this.select = new Select(element);

    }

    protected WebElement waitForVisiblity(By locator) {
        return wait.until(ExpectedConditions.visibilityOfElementLocated(locator));
    }

    protected WebElement waitForClickable(By locator) {
        return wait.until(ExpectedConditions.elementToBeClickable(locator));
    }

    protected void waitforDisaspperWebElement(By locator) {
        wait.until(ExpectedConditions.invisibilityOfElementLocated(locator));
    }

    protected void waitforPagetitleElement(String title) {
        wait.until(ExpectedConditions.titleContains(title));
    }

    protected void click(By locator) {
        waitForClickable(locator);
    }

    protected void click(WebElement element) {
        wait.until(ExpectedConditions.elementToBeClickable(element)).click();
    }

    protected void setText(By locator, String text) {
        WebElement element = waitForVisiblity(locator);
        element.clear();
        element.sendKeys(text);
    }

    protected void clear(By locator) {
        WebElement element = waitForVisiblity(locator);
        element.clear();
    }

    protected String getText(By locator) {

        return waitForVisiblity(locator).getText();
    }

    protected String getAttribute(
            By locator,
            String attributeName) {

        return waitForVisiblity(locator)
                .getAttribute(attributeName);
    }

    // =========================================================
    // Element State
    // =========================================================

    protected boolean isDisplayed(By locator) {

        try {

            return waitForVisiblity(locator)
                    .isDisplayed();

        } catch (Exception e) {

            return false;
        }
    }

    protected boolean isEnabled(By locator) {

        try {

            return waitForVisiblity(locator)
                    .isEnabled();

        } catch (Exception e) {

            return false;
        }
    }

    // =========================================================
    // Dropdown
    // =========================================================

    protected void selectByVisibleText(
            By locator,
            String visibleText) {

        // WebElement element =
        // waitForVisiblity(locator);

        select.selectByVisibleText(visibleText);
    }

    protected void selectByValue(
            By locator,
            String value) {

        // WebElement element =
        // waitForVisiblity(locator);

        select.selectByValue(value);
    }

    // =========================================================
    // Mouse Actions
    // =========================================================

    protected void hover(By locator) {

        WebElement element = waitForVisiblity(locator);

        actions.moveToElement(element)
                .perform();
    }

    protected void doubleClick(By locator) {

        WebElement element = waitForClickable(locator);

        actions.doubleClick(element)
                .perform();
    }

    // =========================================================
    // Scrolling
    // =========================================================

    protected void scrollToElement(By locator) {

        WebElement element = waitForVisiblity(locator);

        actions.scrollToElement(element)
                .perform();
    }

    // =========================================================
    // JavaScript
    // =========================================================

    protected void scrollToBottom() {

        ((org.openqa.selenium.JavascriptExecutor) driver)
                .executeScript(
                        "window.scrollTo(0, document.body.scrollHeight);");
    }

    protected void scrollToTop() {

        ((org.openqa.selenium.JavascriptExecutor) driver)
                .executeScript(
                        "window.scrollTo(0, 0);");
    }

    // =========================================================
    // URL
    // =========================================================

    protected void navigateTo(String url) {

        driver.get(url);
    }

    protected String getCurrentUrl() {

        return driver.getCurrentUrl();
    }

    // =========================================================
    // Browser
    // =========================================================

    protected String getPageTitle() {

        return driver.getTitle();
    }
}