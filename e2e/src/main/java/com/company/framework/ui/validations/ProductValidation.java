package com.company.framework.ui.validations;

import org.testng.Assert;

public final class ProductValidation {
    private ProductValidation() {
    }

    public static void verifyProductAvailability(boolean productFound, boolean expectedAvailable,
            String productName) {
        Assert.assertEquals(productFound, expectedAvailable,
                "Unexpected product availability for: " + productName);
    }
}
