# code-migration-research

Bachelor's thesis research: evaluating the Junie coding agent on Java 8 → 17 repository migration against OpenRewrite.
Weekly posts: [week-01.md](week-01.md), [week-02.md](week-02.md).

## Week 1

`run.sh` clones a repo at a given commit, runs `mvn clean verify` on JDK 8 and JDK 17,
applies OpenRewrite `UpgradeToJava17` and builds again on JDK 17.
Requires Maven on `PATH` (I used 3.9.6) and `JDK8_HOME` / `JDK17_HOME`.

```sh
./run.sh jarlehansen/springfox-loader cdd05aff73e94bfbb7fc21f0b5fcd78c13eab5c5
```

## Week 2

`run.sh` can also migrate with Junie (needs `JUNIE_API_KEY`, see https://junie.jetbrains.com/cli).
The model is pinned to `gpt-6-luna` by default (override with `JUNIE_MODEL`); the last argument is the run number.

```sh
./run.sh dropwizard/dropwizard-elasticsearch 22b4e6418177f73681a73f46d961c26bf9d290ab junie 1
./run.sh TaoZhuGongBoy/enumstatemachine c113642308637e8836b2abaf3514b3aa285800b7 junie 1
./run.sh jarlehansen/springfox-loader cdd05aff73e94bfbb7fc21f0b5fcd78c13eab5c5 junie 2
```

Results: `results/week-01.txt`, `results/week-02.txt`, OpenRewrite and Junie diffs in `results/`.
Repos and commits are from the MigrationBench dataset (`AmazonScience/migration-bench-java-selected`).
