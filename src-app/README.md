# Todo App (Spring Boot, Java 17)

Requirements:
- JDK 17
- (Optional) Docker for PostgreSQL example
- Network access for Gradle dependency resolution

Quick start (using Docker Postgres):

1. Start Postgres:

   docker run --name todo-postgres -e POSTGRES_DB=todo_db -e POSTGRES_USER=todo_user -e POSTGRES_PASSWORD=secret -p 5432:5432 -d postgres:15

2. Build and run:

   cd src-app
   ./gradlew bootRun

3. Open http://localhost:8080/todos

Notes:
- If the included Gradle Wrapper is a placeholder, run `gradle wrapper` locally to generate a real wrapper before using ./gradlew.
- application.properties contains example DB settings. Adjust as needed.
