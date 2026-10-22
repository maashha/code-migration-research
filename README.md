# code-migration-research

Bachelor's thesis research: evaluating the Junie coding agent on Java 8 → 17 repository migration against OpenRewrite.
Weekly posts: [week-01.md](week-01.md).

## Week 1

`run.sh` clones a repo at a given commit, runs `mvn clean verify` on JDK 8 and JDK 17,
applies OpenRewrite `UpgradeToJava17` and builds again on JDK 17.
Requires Maven on `PATH` (I used 3.9.6) and `JDK8_HOME` / `JDK17_HOME`.

```sh
./run.sh jarlehansen/springfox-loader cdd05aff73e94bfbb7fc21f0b5fcd78c13eab5c5
```

Junie was then run once on a clean checkout of the same repo with JDK 17 on `PATH`:

```sh
junie -p work/springfox-loader --output-format=json --task="$(cat prompts/migrate-java17.md)"
```

Results: `results/week-01.txt`, OpenRewrite and Junie diffs in `results/`.
The repo and commit are from the MigrationBench dataset (`AmazonScience/migration-bench-java-selected`).
