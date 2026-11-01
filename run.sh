#!/usr/bin/env bash
# Usage: ./run.sh <owner/repo> <commit> [openrewrite|junie] [run number]
# Builds the repo on JDK 8 and JDK 17, migrates it with OpenRewrite UpgradeToJava17 (default)
# or with Junie, and builds again on JDK 17.
set -u

REPO=$1
COMMIT=$2
TOOL=${3:-openrewrite}
LABEL=$TOOL; [ "$TOOL" = junie ] && LABEL=junie-${4:-1}
MODEL=${JUNIE_MODEL:-gpt-6-luna}
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

git -C "$DIR" clean -q -fdx
START=$SECONDS
if [ "$TOOL" = junie ]; then
  (JAVA_HOME=$JDK17 PATH=$JDK17/bin:$PATH junie --skip-update-check --model="$MODEL" -p "$DIR" --output-format=json \
    --json-output-file="$ROOT/work/$NAME.$LABEL.json" --task="$(cat "$ROOT/prompts/migrate-java17.md")" \
    > "$ROOT/work/$NAME.$LABEL.agent.log" 2>&1)
  if grep -q '"errors"' "$ROOT/work/$NAME.$LABEL.json"; then
    echo "$NAME | $LABEL | JUNIE ERROR: $(cat "$ROOT/work/$NAME.$LABEL.json")"; exit 1
  fi
else
  (cd "$DIR" && JAVA_HOME=$JDK17 PATH=$JDK17/bin:$PATH mvn -B -s "$ROOT/settings.xml" \
    org.openrewrite.maven:rewrite-maven-plugin:6.46.1:run \
    -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-migrate-java:3.42.1 \
    -Drewrite.activeRecipes=org.openrewrite.java.migrate.UpgradeToJava17 > "$ROOT/work/$NAME.$LABEL.agent.log" 2>&1)
fi
echo "$NAME | $LABEL | took $((SECONDS - START)) s"
git -C "$DIR" clean -q -fdX  # drop build output Junie left behind before diffing
git -C "$DIR" diff > "$ROOT/results/$NAME.$LABEL.diff"
git -C "$DIR" status --short

build "$JDK17" "$LABEL"
if [ "$TOOL" = junie ]; then
  python3 -c 'import json, sys; u = json.load(open(sys.argv[1]))["llmUsage"]
print("cost $%.3f, models:" % sum(m["cost"] for m in u), ", ".join(m["model"] for m in u))' "$ROOT/work/$NAME.$LABEL.json"
fi
