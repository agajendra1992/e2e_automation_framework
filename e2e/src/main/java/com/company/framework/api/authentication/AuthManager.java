package com.company.framework.api.authentication;

import com.company.framework.api.services.LoginService;
import com.company.framework.models.request.TokenAuthentication;

public class AuthManager {
	private final LoginService loginService;

	public AuthManager() {
		this.loginService = new LoginService();
	}

	public String authenticate(String username, String password) {
		String token = loginService.authenticate(new TokenAuthentication(username, password))
				.then()
				.statusCode(200)
				.extract()
				.jsonPath()
				.getString("token");
		if (token == null || token.isBlank()) {
			throw new IllegalStateException("Authentication response did not contain a token");
		}
		TokenManager.setToken(token);
		return token;
	}
}
