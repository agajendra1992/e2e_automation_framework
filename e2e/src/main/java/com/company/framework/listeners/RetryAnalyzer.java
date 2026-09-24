package com.company.framework.listeners;

import org.testng.IRetryAnalyzer;
import org.testng.ITestResult;

public class RetryAnalyzer implements IRetryAnalyzer {
	private int attempts;
	private static final int MAX_RETRIES = 1;

	@Override
	public boolean retry(ITestResult result) {
		if (attempts < MAX_RETRIES) {
			attempts++;
			return true;
		}
		return false;
	}
}
