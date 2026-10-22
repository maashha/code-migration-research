Migrate this Maven project from Java 8 to Java 17.

Requirements:
- The project must build and all tests must pass with `mvn clean verify` on JDK 17 (JDK 17 and Maven are already on PATH).
- Compiled classes must target Java 17 (class file major version 61), e.g. via `maven.compiler.release` = 17.
- Upgrade dependencies and plugins where necessary for Java 17 compatibility.
- Do not delete, disable, skip or weaken existing tests, and do not change test logic.
- Keep changes focused on the migration; do not refactor unrelated code.

When finished, run `mvn clean verify` one final time and report the result.
