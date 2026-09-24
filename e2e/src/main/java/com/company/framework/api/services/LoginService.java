package com.company.framework.api.services;

import com.company.framework.api.client.ApiClient;
import com.company.framework.models.request.TokenAuthentication;

import io.restassured.response.Response;

public class LoginService {
	private final ApiClient client;

	public LoginService() {
		this(new ApiClient());
	}

	public LoginService(ApiClient client) {
		this.client = client;
	}

	public Response authenticate(TokenAuthentication credentials) {
		return client.post("auth", credentials);
	}
}
