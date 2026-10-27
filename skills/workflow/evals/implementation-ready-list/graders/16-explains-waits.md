---
type: llm
focus: last_message
---
PASS if the final reply says L3a and L4a were started, L3b waits because its Surface shares
src/server/quotes.route.ts with L3a, which is now running, and L4b waits because the layer it
depends on, L3b, has not merged into the feature branch.
FAIL if it says L3b or L4b started, or gives no reason for either wait. Exit codes and notes about
the environment do not matter.
