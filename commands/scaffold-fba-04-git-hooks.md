---
nome: scaffold-fba-04-git-hooks
descricao: Variante FBA — fase 4, git hooks
tipo: comando
idioma: en
---
# Role
Senior Frontend Architect & DevOps Engineer

# Objective
Initialize Git repository with Husky, lint-staged, commitlint, and cz-git for conventional commits. This ensures code quality and standardized commit messages through automated hooks.

# Constraints
- **Package Manager:** ALWAYS use `bun`. Never use npm, pnpm or yarn.
- **Versions:** NEVER specify version numbers. Always use `latest` or `@latest`.
- **Hook Safety:** Pre-commit hooks must handle errors gracefully and provide helpful messages.
- **Commit Standards:** Must enforce Conventional Commits specification.
- **Error Handling:** Stop immediately if any command fails.

# Chain of Thought
1. Verify Phases 1-3 completed successfully
2. Initialize Git repository (if not already initialized)
3. Install Husky, lint-staged, commitlint, and cz-git
4. Configure Husky hooks
5. Create commitlint configuration with cz-git prompts
6. Configure package.json with commitizen and lint-staged settings
7. Make hooks executable
8. Test commit flow

# Execution

## Step 1: Initialize Git

```bash
git init
```

**Note:** Skip this if `.git` directory already exists.

## Step 2: Install Dependencies

```bash
bun add -d husky lint-staged @commitlint/cli @commitlint/config-conventional @commitlint/types cz-git czg
```

**Anti-Pattern:** In CI, do not reach for a tool that is not a declared dependency. `bunx` looks for the local package first and only then downloads, so `bunx lint-staged` inside a hook resolves the installed binary — but `bunx <something-not-installed>` runs whatever is published at that moment. Declare the tool, and call it through a script with `bun run <script>` (`BUN-CORE-06`).

## Step 3: Initialize Husky

```bash
bunx husky init
```

## Step 4: Create Pre-commit Hook

Create `.husky/pre-commit`:

```bash
#!/bin/sh
# Pre-commit hook with error handling

if ! bunx lint-staged; then
  echo ""
  echo "❌ Pre-commit checks failed. Please fix the issues above and try again."
  echo "💡 You can run 'bunx biome check --write .' to fix issues automatically."
  echo ""
  exit 1
fi

echo ""
echo "✅ Pre-commit checks passed!"
echo ""
```

Make it executable:

```bash
chmod +x .husky/pre-commit
```

**Critical Fix:** The original had `bunx lint-staged` twice. This version calls it once with proper error handling.

**Anti-Pattern:** Do NOT run lint-staged multiple times in the same hook.

## Step 5: Create Commit Message Hook

Create `.husky/commit-msg`:

```bash
#!/bin/sh
bunx commitlint --edit $1
```

Make it executable:

```bash
chmod +x .husky/commit-msg
```

## Step 6: Create Commitlint Configuration

Create `commitlint.config.ts`:

```typescript
import { RuleConfigSeverity } from "@commitlint/types";

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    "body-leading-blank": [RuleConfigSeverity.Warning, "always"],
    "body-max-line-length": [RuleConfigSeverity.Error, "always", 100],
    "footer-leading-blank": [RuleConfigSeverity.Warning, "always"],
    "footer-max-line-length": [RuleConfigSeverity.Error, "always", 100],
    "header-max-length": [RuleConfigSeverity.Error, "always", 100],
    "header-trim": [RuleConfigSeverity.Error, "always"],
    "subject-case": [
      RuleConfigSeverity.Error,
      "never",
      ["sentence-case", "start-case", "pascal-case", "upper-case"],
    ],
    "subject-empty": [RuleConfigSeverity.Error, "never"],
    "subject-full-stop": [RuleConfigSeverity.Error, "never", "."],
    "type-case": [RuleConfigSeverity.Error, "always", "lower-case"],
    "type-empty": [RuleConfigSeverity.Error, "never"],
    "type-enum": [
      RuleConfigSeverity.Error,
      "always",
      [
        "build",
        "chore",
        "ci",
        "docs",
        "feat",
        "fix",
        "perf",
        "refactor",
        "revert",
        "style",
        "test",
      ],
    ],
  },
  prompt: {
    questions: {
      type: {
        description: "Select the type of change that you're committing",
        enum: {
          feat: {
            description: "A new feature",
            title: "Features",
            emoji: "✨",
          },
          fix: {
            description: "A bug fix",
            title: "Bug Fixes",
            emoji: "🐛",
          },
          docs: {
            description: "Documentation only changes",
            title: "Documentation",
            emoji: "📚",
          },
          style: {
            description: "Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)",
            title: "Styles",
            emoji: "💎",
          },
          refactor: {
            description: "A code change that neither fixes a bug nor adds a feature",
            title: "Code Refactoring",
            emoji: "📦",
          },
          perf: {
            description: "A code change that improves performance",
            title: "Performance Improvements",
            emoji: "🚀",
          },
          test: {
            description: "Adding missing tests or correcting existing tests",
            title: "Tests",
            emoji: "🚨",
          },
          build: {
            description: "Changes that affect the build system or external dependencies",
            title: "Builds",
            emoji: "🛠",
          },
          ci: {
            description: "Changes to our CI configuration files and scripts",
            title: "Continuous Integrations",
            emoji: "⚙️",
          },
          chore: {
            description: "Other changes that don't modify src or test files",
            title: "Chores",
            emoji: "♻️",
          },
          revert: {
            description: "Reverts a previous commit",
            title: "Reverts",
            emoji: "🗑",
          },
        },
      },
      scope: {
        description: "What is the scope of this change (e.g. component or file name)",
      },
      subject: {
        description: "Write a short, imperative tense description of the change",
      },
      body: {
        description: "Provide a longer description of the change",
      },
      isBreaking: {
        description: "Are there any breaking changes?",
      },
      breakingBody: {
        description: "A BREAKING CHANGE commit requires a body. Please enter a longer description of the commit itself",
      },
      breaking: {
        description: "Describe the breaking changes",
      },
      isIssueAffected: {
        description: "Does this change affect any open issues?",
      },
      issuesBody: {
        description: "If issues are closed, the commit requires a body. Please enter a longer description of the commit itself",
      },
      issues: {
        description: 'Add issue references (e.g. "fix #123", "re #123".)',
      },
    },
  },
};
```

## Step 7: Configure Package.json

Add to `package.json`:

```json
{
  "config": {
    "commitizen": {
      "path": "node_modules/cz-git",
      "useEmoji": true
    }
  },
  "lint-staged": {
    "*.{ts,tsx,js,jsx,stories,stories.tsx,json}": [
      "bun run lint:staged --no-errors-on-unmatched"
    ]
  },
  "scripts": {
    "commit": "czg"
  }
}
```

## Step 8: Test the Setup

Create a test file to verify hooks work:

```bash
# Create a test file
echo "// Test file" > test-hooks.txt

# Stage it
git add test-hooks.txt

# Try to commit (this should trigger the interactive commit flow)
bun run commit

# Clean up after test
rm test-hooks.txt
```

**Anti-Pattern:** Do NOT use `git commit -m "test"` to bypass commitlint. Use `bun run commit` for interactive flow.

# Verification Checklist

Before proceeding to Phase 5, verify ALL of these:

- [ ] `.husky/pre-commit` hook exists and is executable
- [ ] `.husky/commit-msg` hook exists and is executable
- [ ] `commitlint.config.ts` exists with cz-git prompt configuration
- [ ] `package.json` has `config.commitizen` section
- [ ] `package.json` has `lint-staged` configuration
- [ ] `package.json` has `commit` script
- [ ] `.git` directory exists (Git is initialized)

**Verification Commands:**
```bash
# Check hooks are executable
ls -la .husky/

# Verify commitizen works (dry run)
echo "test" | bunx commitlint --config commitlint.config.ts
```

**Failure Recovery:** If hooks fail, check file permissions with `chmod +x .husky/*`.

# Output Format

Provide a concise summary including:
1. Confirmation that Git is initialized
2. Confirmation that Husky hooks are configured
3. Confirmation that commitlint is configured with cz-git
4. Status: "✅ Ready for Phase 5: FBA Directory Structure"

# Error Handling

If any command fails:
1. Stop execution immediately
2. Report the exact error message
3. For hook failures, verify file permissions
4. Do not proceed to next steps

# Troubleshooting

**Issue:** "husky - command not found"
**Solution:** Run `bunx husky install` to reinitialize Husky.

**Issue:** Pre-commit hook runs but doesn't fail on errors
**Solution:** Ensure the hook script checks exit codes with `if ! command; then ... fi`.

**Issue:** "commitlint: command not found"
**Solution:** Use `bunx commitlint` instead of direct command.

**Issue:** cz-git doesn't show interactive prompt
**Solution:** Make sure `config.commitizen.path` points to `node_modules/cz-git` in package.json.
