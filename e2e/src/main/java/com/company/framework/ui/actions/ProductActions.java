package com.company.framework.ui.actions;

import java.util.List;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;

import com.company.framework.ui.pages.ProductsPage;
import com.company.framework.ui.pages.UIBaseUtils;

public class ProductActions extends UIBaseUtils {
    private final ProductsPage productsPage = new ProductsPage();

    public ProductActions(WebDriver driver) {
        super(driver, null, null, null, null);
    }

    public boolean searchProduct(String productName) {
        List<WebElement> products = wait.until(
            ExpectedConditions.presenceOfAllElementsLocatedBy(productsPage.productNames()));

        return products.stream()
                .anyMatch(product -> product.getText().trim().equalsIgnoreCase(productName));
    }
}
