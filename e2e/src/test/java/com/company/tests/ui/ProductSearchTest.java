package com.company.tests.ui;

import java.util.Map;

import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import com.company.framework.config.ConfigManager;
import com.company.framework.utils.ExcelUtils;
import com.company.framework.ui.actions.LoginActions;
import com.company.framework.ui.actions.ProductActions;
import com.company.framework.ui.driver.DriverManager;
import com.company.framework.ui.validations.ProductValidation;
import com.company.tests.base.UIBaseTest;

public class ProductSearchTest extends UIBaseTest {
    @DataProvider(name = "productData")
    public Object[][] productData() {
        return ExcelUtils.readCsv("testdata/product-search-data.csv");
    }

    @Test(dataProvider = "productData")
    public void searchProduct(Map<String, String> productData) {
        LoginActions loginActions = new LoginActions(DriverManager.getDriver());
        loginActions.loginCredentials(ConfigManager.get("ui.username"), ConfigManager.get("ui.password"));
        loginActions.submitLogin();

        String productName = productData.get("productName");
        boolean expectedAvailable = Boolean.parseBoolean(productData.get("expectedAvailable"));
        ProductActions productActions = new ProductActions(DriverManager.getDriver());
        boolean productFound = productActions.searchProduct(productName);

        ProductValidation.verifyProductAvailability(productFound, expectedAvailable, productName);
    }
}
