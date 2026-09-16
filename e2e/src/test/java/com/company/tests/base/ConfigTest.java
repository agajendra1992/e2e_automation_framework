package com.company.tests.base;

import com.company.framework.config.ConfigManager;
import org.testng.annotations.*;
import static org.testng.Assert.assertNotNull;
public class ConfigTest {
    @Test 
    public void verifyConfiguration(){
        String apiurl = ConfigManager.get("api.base.url");
        String uiurl = ConfigManager.get("ui.base.url");
        String browser = ConfigManager.get("browser");

        assertNotNull(apiurl);
        assertNotNull(uiurl);
        assertNotNull(browser);
    
        

    }
}
