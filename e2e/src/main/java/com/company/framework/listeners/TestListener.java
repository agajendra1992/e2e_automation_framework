package com.company.framework.listeners;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.ITestContext;
import org.testng.ITestListener;
import org.testng.ITestResult;

import com.aventstack.extentreports.Status;
import com.company.framework.reporting.ExtentManager;

public class TestListener implements ITestListener {
	private static final Logger LOGGER = LoggerFactory.getLogger(TestListener.class);

	@Override
	public void onStart(ITestContext context) {
		ExtentManager.initialize();
		LOGGER.info("Starting TestNG context: {}", context.getName());
	}

	@Override
	public void onTestStart(ITestResult result) {
		String testName = result.getMethod().getQualifiedName();
		ExtentManager.startTest(testName, result.getMethod().getDescription());
		LOGGER.info("Starting test: {}", testName);
	}

	@Override
	public void onTestSuccess(ITestResult result) {
		if (ExtentManager.getTest() != null) {
			ExtentManager.getTest().log(Status.PASS, "Test passed");
		}
		LOGGER.info("Passed: {}", result.getMethod().getQualifiedName());
		ExtentManager.endTest();
	}

	@Override
	public void onTestFailure(ITestResult result) {
		if (ExtentManager.getTest() != null) {
			ExtentManager.getTest().log(Status.FAIL, result.getThrowable());
		}
		LOGGER.error("Failed: {}", result.getMethod().getQualifiedName(), result.getThrowable());
		ExtentManager.endTest();
	}

	@Override
	public void onTestSkipped(ITestResult result) {
		if (ExtentManager.getTest() != null) {
			ExtentManager.getTest().log(Status.SKIP, "Test skipped");
		}
		LOGGER.warn("Skipped: {}", result.getMethod().getQualifiedName());
		ExtentManager.endTest();
	}

	@Override
	public void onFinish(ITestContext context) {
		ExtentManager.flush();
		LOGGER.info("Finished TestNG context: {}", context.getName());
	}
}
