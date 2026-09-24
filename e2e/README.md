## E2E Automation Framework

This is a Java 17 Maven automation framework that supports both UI and API tests.
TestNG controls execution, Selenium drives browsers, Rest Assured handles HTTP,
Jackson models request payloads, SLF4J/Logback provide logs, and Extent Reports
produces an HTML execution report.

### Execution flow

```text
Maven -> testng.xml -> TestNG listeners
		    -> UIBaseTest -> DriverFactory -> Page/Action/Validation
		    -> APIBaseTest -> AuthManager -> Service -> ApiClient -> API
		    -> TestListener -> Extent report + Logback logs
```

### Folder responsibilities

| Folder | Responsibility |
| --- | --- |
| `src/main/java/.../api/client` | Common HTTP verbs and request execution |
| `src/main/java/.../api/services` | Endpoint-level business operations such as booking and authentication |
| `src/main/java/.../api/specifications` | Shared base URI, headers, and response specifications |
| `src/main/java/.../api/authentication` | API token creation, storage, and cleanup |
| `src/main/java/.../api/validations` | API response assertions and contract validation |
| `src/main/java/.../models` | Typed request and response payload objects; Lombok generates model accessors and constructors |
| `src/main/java/.../ui/driver` | Browser selection, options, WebDriver creation, and thread-safe storage |
| `src/main/java/.../ui/pages` | Page locators and common Selenium interactions |
| `src/main/java/.../ui/actions` | User workflows such as login |
| `src/main/java/.../ui/validations` | UI assertions and state checks |
| `src/main/java/.../config` | Environment property loading through `-Denv` |
| `src/main/java/.../listeners` | Retry, TestNG lifecycle, logging, and report events |
| `src/main/java/.../reporting` | Extent Reports lifecycle and output configuration |
| `src/main/java/.../database` | Reserved database connection and query utilities |
| `src/main/java/.../utils` | Reusable JSON and Excel helpers |
| `src/test/java/.../tests` | Test cases and UI/API base setup |
| `src/test/resources` | Environment properties and Logback test logging configuration |

### API design

Tests call services, not raw URLs. Lombok keeps the model classes concise while
still providing getters, setters, and no-argument/all-argument constructors:

```java
BookingRequest request = new BookingRequest(
	"Jim", "Brown", 111, true,
	new BookingDates("2026-01-01", "2026-01-05"), "Breakfast");

Response created = bookingService.createBooking(request);
Response fetched = bookingService.getBooking(created.jsonPath().getInt("bookingid"));
```

`ApiClient` centralizes `GET`, `POST`, `PUT`, and `DELETE`, applies common
specifications, logs method/status, and supports the Restful Booker token cookie
for update and delete operations.

### JSON test data

API payloads can be stored under `src/test/resources/testdata` and converted to
typed models with Jackson through `JSONUtils`:

```java
BookingRequest request = JSONUtils.fromResource(
	"testdata/booking-request.json", BookingRequest.class);

String json = JSONUtils.toJson(request);
```

`fromJson` deserializes a JSON string, `fromResource` deserializes a classpath
resource, and `toJson` serializes a Java object into JSON.

### Excel-style TestNG DataProvider

`ProductSearchTest` uses the `productData` DataProvider to execute one UI test
per row from `src/test/resources/testdata/product-search-data.csv`. The CSV is
Excel-compatible and contains the columns `productName` and `expectedAvailable`.
`ExcelUtils` also supports native `.xlsx` files through `readSheet(resource, sheet)`
when a workbook is supplied:

```java
return ExcelUtils.readSheet("testdata/product-search-data.xlsx", "Products");
```

### Run tests

```bash
mvn clean test -Denv=qa -Dbrowser=chrome
```

Use `-Denv=dev` for the development properties file and set `-Dbrowser=firefox`
or `-Dbrowser=edge` when needed. Headless execution is controlled by the selected
environment property.

### API Docker image and EC2 deployment

The API-only suite is defined in `testng-api.xml` and packaged by `Dockerfile.api`.
It does not start Selenium or run the UI tests.

Build and run the image locally:

```bash
docker build -f Dockerfile.api -t e2e-api-suite:latest .
docker run --rm -v "$PWD/target:/workspace/target" \
	e2e-api-suite:latest -Denv=qa
```

Deploy the same image to an Ubuntu EC2 instance over SSH:

```bash
EC2_HOST=ec2-xx-xx-xx-xx.compute-1.amazonaws.com \
KEY_PATH=/path/to/qa-automation-key.pem \
ENVIRONMENT=qa \
bash deploy-api-ec2.sh
```

The deployment script builds the image locally, transfers it to EC2, installs
Docker if necessary, runs the API suite, and stores reports and logs under
`/opt/e2e-api-suite/results` on the instance. Do not commit private keys or AWS
credentials; use SSH keys and an instance role or environment-based AWS
credentials outside the repository.

### UI suite and Docker image

The UI-only suite is defined in `testng-ui.xml`. `Dockerfile.ui` installs
Chromium and ChromiumDriver, runs the existing headless Selenium flow, and
stores the same reports and logs in the mounted `target` directory.

```bash
docker build -f Dockerfile.ui -t e2e-ui-suite:latest .
docker run --rm -v "$PWD/target:/workspace/target" \
	e2e-ui-suite:latest -Denv=qa
```

The API and UI suites can therefore be run independently:

```bash
mvn clean test -Dtestng.suite=testng-api.xml -Denv=qa
mvn clean test -Dtestng.suite=testng-ui.xml -Denv=qa -Dbrowser=chrome
```

### Jenkins image pipeline to EC2

`JenkinsFile` builds and tags the selected Docker image, pushes both the build
number and `latest` tags to Docker Hub, pulls the immutable build tag on EC2,
runs the container, downloads the reports, and fails the Jenkins build when the
remote suite fails.

Configure these Jenkins credentials before creating the pipeline job:

| Credential ID | Type | Purpose |
| --- | --- | --- |
| `docker-registry` | Username with password/token | Push and pull the Docker image |
| `ec2-ssh-key` | SSH Username with private key | Connect to the EC2 instance |

Create a Pipeline job using `JenkinsFile`, then provide these parameters:

- `SUITE`: `api` or `ui`
- `ENVIRONMENT`: `qa` or `dev`
- `IMAGE_REPOSITORY`: Docker registry repository, for example `myuser/e2e-suite`
- `EC2_HOST`: EC2 public DNS name or IP address
- `EC2_USER`: usually `ubuntu`

The Jenkins agent needs Docker, Maven, Java, SSH, and SCP. The EC2 instance
needs network access to the registry and the application endpoints. The
pipeline installs Docker on Ubuntu EC2 when it is missing, runs the image under
`/opt/e2e-api-suite` or `/opt/e2e-ui-suite`, and archives the results in the
Jenkins build under `target/ec2-results`.

### Outputs

- Extent report: `target/extent-report/extent-report.html`
- Automation log: `target/logs/automation.log`
- Maven/TestNG reports: `target/surefire-reports`

### AI pull request review

The workflow at `.github/workflows/ai-pr-review.yml` reviews every non-draft pull
request using GitHub Models. It reads the pull request diff without checking out
or executing contributor code, posts an AI review, and fails the `AI PR Review`
status check when the model reports blocking findings.

To prevent merging without review, configure the repository's default branch
under **Settings -> Branches -> Branch protection rules** with:

1. Require a pull request before merging.
2. Require at least one approving human review.
3. Require status checks to pass and select `AI PR Review / AI PR Review`.
4. Require branches to be up to date before merging.
5. Apply the rule to administrators as well.

The workflow requires GitHub Models access for the repository. The model can be
changed through the `MODEL` value in the workflow if the organization uses a
different approved model.

### Interview explanation

The framework follows separation of concerns. Tests describe business intent,
services describe API operations, clients describe transport, models describe
payloads, and listeners/reporting describe execution evidence. UI tests follow
the same idea through page objects, actions, validations, and a thread-local
driver manager. This keeps tests readable and makes shared behavior change in
one place.


