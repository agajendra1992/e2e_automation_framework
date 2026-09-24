package com.company.framework.api.authentication;

public class TokenManager {
	private static final ThreadLocal<String> TOKEN = new ThreadLocal<>();

	private TokenManager() {
	}

	public static void setToken(String token) {
		TOKEN.set(token);
	}

	public static String getToken() {
		String token = TOKEN.get();
		if (token == null || token.isBlank()) {
			throw new IllegalStateException("API token is not initialized for the current test");
		}
		return token;
	}

	public static void clear() {
		TOKEN.remove();
	}
}
