package com.company.framework.config;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public class ConfigManager {
    private static Properties properties = new Properties();

    static {
        String environment = System.getProperty("env");
        if (environment == null || environment.trim().isEmpty()) {
            environment = "qa";
        }
        // ClassLoader scans target/test-classes directly. No more file paths needed!
        String fileName = "config/config-" + environment.trim() + ".properties";
        
        try (InputStream inputStream = ConfigManager.class.getClassLoader().getResourceAsStream(fileName)) {
            if (inputStream == null) {
                // Let's print out an incredibly clear error message if it still can't find it
                throw new RuntimeException("Property file '" + fileName + "' not found on the classpath. "
                        + "Please ensure it is placed exactly under: src/test/resources/config/");
            }
            properties.load(inputStream);
        } catch (IOException e) {
            throw new RuntimeException("Failed to read configuration file: " + fileName, e);
        }
    }
    
    private ConfigManager() {
        // Prevent instantiation
    }
    
    public static String get(String key) {
        String value = properties.getProperty(key);
        if (value == null) {
            throw new RuntimeException("Missing configuration key: " + key);
        }
        return value;
    }


}

