#!/bin/bash
# Ralph - Long-running AI agent loop
# Usage: ./ralph.sh [max_iterations]

set -euo pipefail

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROGRESS_FILE="$SCRIPT_DIR/progress.txt"

# Init progress file
if [[ ! -f "$PROGRESS_FILE" ]]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Ralph – Max iterations: $MAX_ITERATIONS"

# Main Ralph loop
for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo
  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════"

  echo
  echo ">>> Running Claude at $(date)"
  echo ">>> Iteration $i" >> "$PROGRESS_FILE"

  TMP_OUTPUT=$(mktemp)

  # Run Claude safely
  while true; do
    if cat "$SCRIPT_DIR/prompt.md" \
       | ollama launch claude --model nemotron-3-super -- --dangerously-skip-permissions 2>&1 \
       | tee "$TMP_OUTPUT" | tee -a "$PROGRESS_FILE"; then
      # Success, break out of the retry loop
      break
    else
      # Non-zero exit code: probably spending limit reached
      echo
      echo "⚠️ Claude exited with an error. Possibly spending limit reached."
      echo "Waiting 5 minutes before retry..."
      sleep 300  # 5 minutes
    fi
  done

  OUTPUT=$(cat "$TMP_OUTPUT")
  rm "$TMP_OUTPUT"

  # Completion check
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo
    echo "🎉 Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"

    echo
    echo "Completed: $(date)" >> "$PROGRESS_FILE"
    exit 0
  fi

  echo
  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo
echo "⚠️ Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
