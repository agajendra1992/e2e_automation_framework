package com.company.framework.utils;

import java.io.IOException;
import java.io.InputStream;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

public class JSONUtils {
	private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper()
			.registerModule(new JavaTimeModule());

	private JSONUtils() {
	}

	public static <T> T fromJson(String json, Class<T> targetType) {
		try {
			return OBJECT_MAPPER.readValue(json, targetType);
		} catch (JsonProcessingException exception) {
			throw new IllegalArgumentException("Unable to deserialize JSON into " + targetType.getSimpleName(), exception);
		}
	}

	public static <T> T fromResource(String resourcePath, Class<T> targetType) {
		try (InputStream inputStream = JSONUtils.class.getClassLoader().getResourceAsStream(resourcePath)) {
			if (inputStream == null) {
				throw new IllegalArgumentException("JSON resource not found on classpath: " + resourcePath);
			}
			return OBJECT_MAPPER.readValue(inputStream, targetType);
		} catch (IOException exception) {
			throw new IllegalArgumentException("Unable to deserialize JSON resource: " + resourcePath, exception);
		}
	}

	public static String toJson(Object value) {
		try {
			return OBJECT_MAPPER.writeValueAsString(value);
		} catch (JsonProcessingException exception) {
			throw new IllegalArgumentException("Unable to serialize object to JSON", exception);
		}
	}
}
