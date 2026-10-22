#!/usr/bin/env bash
# Usage: ./run.sh <owner/repo> <commit>
# Builds the repo on JDK 8 and JDK 17, applies OpenRewrite UpgradeToJava17, builds again on JDK 17.
set -u

REPO=$1
COMMIT=$2
NAME=${REPO#*/}
ROOT=$(cd "$(dirname "$0")" && pwd)
JDK8=${JDK8_HOME:?set JDK8_HOME}
JDK17=${JDK17_HOME:?set JDK17_HOME}
DIR=$ROOT/work/$NAME
mkdir -p "$ROOT/work" "$ROOT/results"

build() {  # <jdk home> <label>
  local log=$ROOT/work/$NAME.$2.log
  if (cd "$DIR" && JAVA_HOME=$1 PATH=$1/bin:$PATH mvn -B -s "$ROOT/settings.xml" clean verify > "$log" 2>&1)
  then status=OK; else status=FAIL; fi
  tests=$(grep 'Tests run:' "$log" | tail -1 | sed 's/.*Tests run/Tests run/')
  class=$(find "$DIR" -path '*/target/classes/*.class' | head -1)
  major=$([ -n "$class" ] && "$JDK17/bin/javap" -v "$class" | grep 'major version' | awk '{print $3}')
  echo "$NAME | $2 | $status | ${tests:-no tests run} | major ${major:-?}"
}

[ -d "$DIR" ] || git clone -q "https://github.com/$REPO.git" "$DIR"
git -C "$DIR" checkout -q -f "$COMMIT" && git -C "$DIR" clean -q -fdx

build "$JDK8" jdk8
build "$JDK17" jdk17

(cd "$DIR" && JAVA_HOME=$JDK17 PATH=$JDK17/bin:$PATH mvn -B -s "$ROOT/settings.xml" \
  org.openrewrite.maven:rewrite-maven-plugin:6.46.1:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-migrate-java:3.42.1 \
  -Drewrite.activeRecipes=org.openrewrite.java.migrate.UpgradeToJava17 > "$ROOT/work/$NAME.rewrite.log" 2>&1)
git -C "$DIR" diff > "$ROOT/results/$NAME.openrewrite.diff"

build "$JDK17" openrewrite
