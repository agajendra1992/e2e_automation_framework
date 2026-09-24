package com.company.framework.utils;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;

public final class ExcelUtils {
	private ExcelUtils() {
	}

	public static Object[][] readSheet(String resourcePath, String sheetName) {
		try (InputStream inputStream = ExcelUtils.class.getClassLoader().getResourceAsStream(resourcePath)) {
			if (inputStream == null) {
				throw new IllegalArgumentException("Excel resource not found: " + resourcePath);
			}

			try (Workbook workbook = WorkbookFactory.create(inputStream)) {
				var sheet = workbook.getSheet(sheetName);
				if (sheet == null) {
					throw new IllegalArgumentException("Excel sheet not found: " + sheetName);
				}
				return readRows(sheet.iterator());
			}
		} catch (IOException exception) {
			throw new IllegalArgumentException("Unable to read Excel resource: " + resourcePath, exception);
		}
	}

	public static Object[][] readCsv(String resourcePath) {
		try (InputStream inputStream = ExcelUtils.class.getClassLoader().getResourceAsStream(resourcePath)) {
			if (inputStream == null) {
				throw new IllegalArgumentException("CSV resource not found: " + resourcePath);
			}

			List<String> lines = new java.io.BufferedReader(
					new InputStreamReader(inputStream, StandardCharsets.UTF_8)).lines().toList();
			if (lines.isEmpty()) {
				return new Object[0][0];
			}

			String[] headers = lines.get(0).split(",", -1);
			List<Object[]> records = new ArrayList<>();
			for (String line : lines.subList(1, lines.size())) {
				if (line.isBlank()) {
					continue;
				}
				String[] values = line.split(",", -1);
				Map<String, String> record = new LinkedHashMap<>();
				for (int index = 0; index < headers.length; index++) {
					record.put(headers[index].trim(), index < values.length ? values[index].trim() : "");
				}
				records.add(new Object[] { record });
			}
			return records.toArray(Object[][]::new);
		} catch (IOException exception) {
			throw new IllegalArgumentException("Unable to read CSV resource: " + resourcePath, exception);
		}
	}

	private static Object[][] readRows(Iterator<Row> rows) {
		if (!rows.hasNext()) {
			return new Object[0][0];
		}

		List<String> headers = readHeaders(rows.next());
		List<Map<String, String>> records = new ArrayList<>();
		DataFormatter formatter = new DataFormatter();

		while (rows.hasNext()) {
			Row row = rows.next();
			Map<String, String> record = new LinkedHashMap<>();
			for (int index = 0; index < headers.size(); index++) {
				Cell cell = row.getCell(index, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
				record.put(headers.get(index), cell == null ? "" : formatter.formatCellValue(cell));
			}
			records.add(record);
		}

		return records.stream()
				.map(record -> new Object[] { record })
				.toArray(Object[][]::new);
	}

	private static List<String> readHeaders(Row headerRow) {
		List<String> headers = new ArrayList<>();
		headerRow.forEach(cell -> headers.add(cell.getStringCellValue().trim()));
		return headers;
	}

}