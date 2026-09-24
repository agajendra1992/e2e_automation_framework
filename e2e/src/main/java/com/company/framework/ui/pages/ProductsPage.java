package com.company.framework.ui.pages;

import org.openqa.selenium.By;

public class ProductsPage {
    private static final String PRODUCT_NAMES_SELECTOR = "//div[@class='inventory_item_name']";

    public By productNames() {
        return By.xpath(PRODUCT_NAMES_SELECTOR);
    }

    public By productByName(String productName) {
        return By.xpath("//div[@class='inventory_item_name' and normalize-space()='"
                + productName + "']");
    }
}
