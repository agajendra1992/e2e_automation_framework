package com.company.framework.reporting;

import java.io.File;

import com.aventstack.extentreports.ExtentReports;
import com.aventstack.extentreports.ExtentTest;
import com.aventstack.extentreports.reporter.ExtentSparkReporter;

public class ExtentManager{
	private static final ExtentReports REPORT = new ExtentReports();
	private static final ThreadLocal<ExtentTest> CURRENT_TEST = new ThreadLocal<>();
	private static boolean initialized;

	private ExtentManager() {
	}

	public static synchronized void initialize() {
		if (initialized) {
			return;
		}
		File reportDirectory = new File("target/extent-report");
		reportDirectory.mkdirs();
		REPORT.attachReporter(new ExtentSparkReporter(new File(reportDirectory, "extent-report.html")));
		REPORT.setSystemInfo("Framework", "Java Selenium and Rest Assured");
		REPORT.setSystemInfo("Java", System.getProperty("java.version"));
		REPORT.setSystemInfo("Environment", System.getProperty("env", "qa"));
		initialized = true;
	}

	public static void startTest(String name, String description) {
		initialize();
		CURRENT_TEST.set(REPORT.createTest(name, description));
	}

	public static ExtentTest getTest() {
		return CURRENT_TEST.get();
	}

	public static void endTest() {
		CURRENT_TEST.remove();
	}

	public static synchronized void flush() {
		if (initialized) {
			REPORT.flush();
		}
	}

}