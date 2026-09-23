---
nome: scaffold-projeto
descricao: Orquestra o scaffold completo de um projeto TanStack Start, fase a fase
tipo: comando
idioma: en
tags:
  - frontend
  - tanstack-start
---
# Architect's Scaffold Project

**Role:** Senior Frontend Architect & DevOps Engineer  
**Objective:** Execute complete project scaffolding with zero errors, preserving existing documentation and following Feature-Based Architecture (FBA) standards.

**Priority:** Speed, high-precision analysis, strict phase adherence.  
**Constraint:** No business logic implementation - focus purely on configuration and structure setup.

---

## Pre-Execution: Critical Safety Protocol

**WARNING:** Before ANY initialization commands, execute backup protocol to prevent data loss:

```bash
# Phase 0: Emergency Backup
mkdir -p /tmp/project-backup-$(date +%s)
mv docs /tmp/project-backup-$(date +%s)/ 2>/dev/null || true
mv .agent /tmp/project-backup-$(date +%s)/ 2>/dev/null || true
```

---

## Phase 1: TanStack Start Foundation

**Objective:** Initialize TanStack Start with TypeScript, Tailwind, and Vite.

**Commands:**
```bash
# Create project using TanStack Start CLI
bunx @tanstack/create-start@latest . --tailwind --yes
```

**Post-Init Configuration:**
```bash
# Restore backed-up directories
mv /tmp/project-backup-*/* . 2>/dev/null || true
rm -rf /tmp/project-backup-*

# Create app.config.ts for TanStack Start with FBA path aliases
cat > app.config.ts <<'EOF'
import { defineConfig } from '@tanstack/start/config'
import viteTsConfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  vite: {
    plugins: [
      viteTsConfigPaths({
        projects: ['./tsconfig.json'],
      }),
    ],
  },
})
EOF

# Update tsconfig.json with FBA path aliases
cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx",
    "incremental": true,
    "paths": {
      "@features/*": ["./app/features/*"],
      "@components/*": ["./app/components/*"],
      "@types/*": ["./app/types/*"],
      "@libs/*": ["./app/libs/*"],
      "@utils/*": ["./app/utils/*"]
    }
  },
  "include": ["app/**/*.ts", "app/**/*.tsx", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules", ".output", ".vinxi"]
}
EOF
```

**Verification Checkpoint:**
- [ ] `package.json` exists with TanStack Start dependencies
- [ ] `tsconfig.json` contains all 5 path aliases
- [ ] `app.config.ts` exists with Vite path alias configuration
- [ ] `docs/` and `.agent/` directories are restored

---

## Phase 2: Tooling Configuration (Biome)

**Objective:** Configure Biome with Tailwind CSS support.

**Commands:**
```bash
bunx biome migrate --write
```

**Configuration:**
```bash
cat > biome.json <<'EOF'
{
  "$schema": "https://biomejs.dev/schemas/2.2.0/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "ignoreUnknown": true,
    "includes": ["**", "!node_modules", "!.next", "!dist", "!build"]
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "suspicious": {
        "noUnknownAtRules": "off"
      },
      "style": {
        "useBlockStatements": "off"
      }
    }
  },
  "assist": {
    "actions": {
      "source": {
        "organizeImports": "on"
      }
    }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single"
    }
  }
}
EOF
```

**Verification Checkpoint:**
- [ ] `biome.json` exists with Tailwind support (`noUnknownAtRules: off`)
- [ ] `bunx biome check --version` executes without errors

---

## Phase 3: Testing Infrastructure (`bun test`)

**Objective:** Configure `bun test` with happy-dom and Testing Library. There is **no**
`vitest.config.ts`: `bun test` reads `compilerOptions.paths` from `tsconfig.json`, so the
alias map exists once, not twice.

**Commands:**
```bash
bun add -d @happy-dom/global-registrator @testing-library/react \
            @testing-library/dom @testing-library/jest-dom @testing-library/user-event
```

**Configuration:**
```bash
mkdir -p test

# preload 1 — browser globals first; the order is load-bearing
cat > test/happydom.ts <<'EOF'
import { GlobalRegistrator } from "@happy-dom/global-registrator";

GlobalRegistrator.register();
EOF

# preload 2 — matchers and cleanup. `expect.extend` is mandatory: importing
# "@testing-library/jest-dom" alone does NOT register matchers in bun:test.
cat > test/testing-library.ts <<'EOF'
import { afterEach, expect } from "bun:test";
import { cleanup } from "@testing-library/react";
import * as matchers from "@testing-library/jest-dom/matchers";

expect.extend(matchers);

afterEach(() => {
  cleanup();
  document.body.innerHTML = "";
});
EOF

cat > bunfig.toml <<'EOF'
[test]
preload = ["./test/happydom.ts", "./test/testing-library.ts"]
EOF

# without this, the tests pass and `tsc --noEmit` fails on the matchers
cat > test/matchers.d.ts <<'EOF'
import { TestingLibraryMatchers } from "@testing-library/jest-dom/matchers";
import { Matchers, AsymmetricMatchers } from "bun:test";

declare module "bun:test" {
  interface Matchers<T> extends TestingLibraryMatchers<typeof expect.stringContaining, void> {}
  interface AsymmetricMatchers extends TestingLibraryMatchers<any, any> {}
}
EOF
```

**Verification Checkpoint:**
- [ ] `test/happydom.ts` and `test/testing-library.ts` exist, in that order in `bunfig.toml`
- [ ] `test/matchers.d.ts` exists
- [ ] **No** `vitest.config.ts` — the aliases live only in `tsconfig.json`
- [ ] A test file matches a discovery pattern (`*.test.*`) — outside it, it never runs
      and nothing warns (`BUN-TEST-01`)
- [ ] Break the component on purpose and confirm the suite goes RED (`TS-TEC-08`)

---

## Phase 4: Git & Hooks Setup

**Objective:** Initialize Git, Husky, lint-staged, and Commitlint.

**Commands:**
```bash
git init
bun add -d husky lint-staged @commitlint/cli @commitlint/config-conventional
bunx husky init
```

**Configuration:**

**4.1: Pre-commit Hook**
```bash
cat > .husky/pre-commit <<'EOF'
bunx lint-staged

# Run lint-staged with error handling
if ! bunx lint-staged; then
  echo "❌ Pre-commit checks failed. Please fix the issues above and try again."
  echo "💡 You can run 'bun run lint:staged' to fix issues automatically."
  exit 1
fi

echo "✅ Pre-commit checks passed!"
EOF
chmod +x .husky/pre-commit
```

**4.2: Commit Message Hook**
```bash
echo "bunx commitlint --edit \$1" > .husky/commit-msg
chmod +x .husky/commit-msg
```

**4.3: Commitlint Configuration**
```bash
cat > .commitlintrc.json <<'EOF'
{
  "extends": ["@commitlint/config-conventional"]
}
EOF
```

**Verification Checkpoint:**
- [ ] `.husky/pre-commit` hook exists and is executable with lint-staged error handling
- [ ] `.husky/commit-msg` hook exists and is executable
- [ ] `.commitlintrc.json` extends conventional config

---

## Phase 5: FBA Directory Structure

**Objective:** Create Feature-Based Architecture folder structure with services layer.

**Commands:**
```bash
mkdir -p app/features \
         app/components/ui \
         app/libs \
         app/hooks \
         app/types \
         app/features/news-feed/components \
         app/features/news-feed/hooks \
         app/features/news-feed/api \
         app/features/news-feed/services \
         app/features/news-feed/types \
         app/features/news-feed/utils \
         app/features/news-feed/tests

touch app/features/news-feed/index.ts
```

**Verification Checkpoint:**
- [ ] `app/libs/` exists (NOT `app/lib/`)
- [ ] `app/features/news-feed/services/` directory exists
- [ ] Feature folder structure matches FBA standard with services layer

---

## Phase 6: Shadcn UI Integration

**Objective:** Initialize Shadcn UI and fix import paths for FBA compliance.

**Commands:**
```bash
bunx shadcn@latest init -d
bunx shadcn@latest add card badge -y
```

**Configuration:**
```bash
cat > components.json <<'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@components",
    "utils": "@libs/utils",
    "ui": "@components/ui"
  }
}
EOF
```

**Path Corrections:**
```bash
# Move utils from lib to libs for FBA compliance
mv app/lib/utils.ts app/libs/utils.ts 2>/dev/null || true
rm -rf app/lib 2>/dev/null || true

# Fix import paths in shadcn components
sed -i '' "s|from '@/lib/utils'|from '@libs/utils'|g" app/components/ui/*.tsx 2>/dev/null || \
sed -i "s|from '@/lib/utils'|from '@libs/utils'|g" app/components/ui/*.tsx 2>/dev/null || true
```

**Verification Checkpoint:**
- [ ] `app/libs/utils.ts` exists
- [ ] No `app/lib/` directory exists
- [ ] All UI component imports reference `@libs/utils`

---

## Phase 7: Package.json Scripts

**Objective:** Ensure all required package scripts and lint-staged configuration are present.

**Commands:**
```bash
bun -e "
const pkg = await Bun.file('package.json').json();
pkg.scripts = {
  ...pkg.scripts,
  'dev': 'vinxi dev',
  'build': 'vinxi build',
  'start': 'vinxi start',
  'lint': 'biome check app',
  'lint:fix': 'biome check --apply app',
  'lint:format': 'biome format --write app',
  'lint:staged': 'biome check app --staged --write',
  'typecheck': 'tsc --noEmit',
  'test': 'bun test --watch',
  'test:run': 'bun test',
  'prepare': 'husky'
};
pkg['lint-staged'] = {
  '*.{js,ts,cjs,mjs,d.cts,d.mts,jsx,tsx,json,jsonc}': [
    'bun run lint:staged --no-errors-on-unmatched'
  ]
};
pkg.husky = {
  hooks: {
    'pre-commit': 'lint-staged'
  }
};
await Bun.write('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
```

**Verification Checkpoint:**
- [ ] All 9 scripts are present in `package.json`
- [ ] `lint-staged` configuration exists in `package.json`
- [ ] `husky.hooks.pre-commit` is configured

---

## Phase 8: Example Feature Implementation (News Feed with Services)

**Objective:** Create complete example feature following FBA standards, including the services layer.

**Files to Create:**

```bash
# 1. Types
cat > app/features/news-feed/types/news-feed.type.ts <<'EOF'
export interface NewsArticle {
  id: string;
  title: string;
  summary: string;
  category: string;
  publishedAt: string;
  content?: string;
  author?: string;
  imageUrl?: string;
}

export interface NewsFeedState {
  articles: NewsArticle[];
  isLoading: boolean;
  error: string | null;
}

export interface NewsFeedFilters {
  category?: string;
  fromDate?: string;
  toDate?: string;
  limit?: number;
}
EOF

# 2. Service Layer (Business Logic)
cat > app/features/news-feed/services/news-feed.service.ts <<'EOF'
import type { NewsArticle, NewsFeedFilters } from "../types/news-feed.type";

export class NewsFeedService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api";
  }

  async fetchNews(filters?: NewsFeedFilters): Promise<NewsArticle[]> {
    const params = new URLSearchParams();
    
    if (filters?.category) params.append("category", filters.category);
    if (filters?.fromDate) params.append("from", filters.fromDate);
    if (filters?.toDate) params.append("to", filters.toDate);
    if (filters?.limit) params.append("limit", filters.limit.toString());

    const response = await fetch(`${this.baseUrl}/news?${params.toString()}`);
    
    if (!response.ok) {
      throw new Error(`Failed to fetch news: ${response.statusText}`);
    }

    return response.json();
  }

  async fetchNewsById(id: string): Promise<NewsArticle> {
    const response = await fetch(`${this.baseUrl}/news/${id}`);
    
    if (!response.ok) {
      throw new Error(`Failed to fetch article: ${response.statusText}`);
    }

    return response.json();
  }

  searchNews(query: string, articles: NewsArticle[]): NewsArticle[] {
    const lowerQuery = query.toLowerCase();
    return articles.filter(
      article =>
        article.title.toLowerCase().includes(lowerQuery) ||
        article.summary.toLowerCase().includes(lowerQuery)
    );
  }

  filterByCategory(articles: NewsArticle[], category: string): NewsArticle[] {
    return articles.filter(article => article.category === category);
  }

  sortByDate(articles: NewsArticle[], order: "asc" | "desc" = "desc"): NewsArticle[] {
    return [...articles].sort((a, b) => {
      const dateA = new Date(a.publishedAt).getTime();
      const dateB = new Date(b.publishedAt).getTime();
      return order === "desc" ? dateB - dateA : dateA - dateB;
    });
  }
}

// Export singleton instance for common use
export const newsFeedService = new NewsFeedService();
EOF

# 3. API Layer (Thin Wrapper)
cat > app/features/news-feed/api/news-feed.api.ts <<'EOF'
import { newsFeedService } from "@services/news-feed.service";
import type { NewsArticle, NewsFeedFilters } from "../types/news-feed.type";

export async function fetchNews(filters?: NewsFeedFilters): Promise<NewsArticle[]> {
  return newsFeedService.fetchNews(filters);
}

export async function fetchNewsById(id: string): Promise<NewsArticle> {
  return newsFeedService.fetchNewsById(id);
}
EOF

# 4. Hook
cat > app/features/news-feed/hooks/use-news.hook.ts <<'EOF'
"use client";

import { useState, useEffect, useCallback } from "react";
import { newsFeedService } from "../services/news-feed.service";
import type { NewsArticle, NewsFeedState, NewsFeedFilters } from "../types/news-feed.type";

export function useNews(filters?: NewsFeedFilters) {
  const [state, setState] = useState<NewsFeedState>({
    articles: [],
    isLoading: true,
    error: null,
  });

  const fetchNews = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));
    
    try {
      const articles = await newsFeedService.fetchNews(filters);
      setState({ articles, isLoading: false, error: null });
    } catch (err) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: err instanceof Error ? err.message : "Failed to fetch news",
      }));
    }
  }, [filters]);

  useEffect(() => {
    fetchNews();
  }, [fetchNews]);

  return {
    ...state,
    refetch: fetchNews,
  };
}
EOF

# 5. Component
cat > app/features/news-feed/components/news-card.component.tsx <<'EOF'
import { Card, CardContent, CardHeader, CardTitle } from "@components/ui/card";
import { Badge } from "@components/ui/badge";
import type { NewsArticle } from "../types/news-feed.type";

interface NewsCardProps {
  article: NewsArticle;
}

export function NewsCard({ article }: NewsCardProps) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg">{article.title}</CardTitle>
          <Badge variant="secondary">{article.category}</Badge>
        </div>
      </CardHeader>
      <CardContent>
        <p className="text-sm text-muted-foreground">{article.summary}</p>
        <time className="text-xs text-muted-foreground mt-2 block">
          {new Date(article.publishedAt).toLocaleDateString()}
        </time>
      </CardContent>
    </Card>
  );
}
EOF

# 6. Utils
cat > app/features/news-feed/utils/news-feed.util.ts <<'EOF'
import type { NewsArticle } from "../types/news-feed.type";

export function formatPublishedDate(dateString: string): string {
  return new Date(dateString).toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}
EOF

# 7. Test
cat > app/features/news-feed/tests/news-feed.test.tsx <<'EOF'
import { describe, it, expect } from 'bun:test';
import { render, screen, waitFor } from '@testing-library/react';
import { NewsCard } from '../components/news-card.component';
import { NewsFeedService } from '../services/news-feed.service';
import type { NewsArticle } from '../types/news-feed.type';

const mockArticle: NewsArticle = {
  id: '1',
  title: 'Test Article',
  summary: 'This is a test summary',
  category: 'Test',
  publishedAt: '2023-10-01T00:00:00Z',
};

describe('NewsCard', () => {
  it('renders article title', () => {
    render(<NewsCard article={mockArticle} />);
    expect(screen.getByText('Test Article')).toBeInTheDocument();
  });

  it('renders article category badge', () => {
    render(<NewsCard article={mockArticle} />);
    expect(screen.getByText('Test')).toBeInTheDocument();
  });

  it('renders article summary', () => {
    render(<NewsCard article={mockArticle} />);
    expect(screen.getByText('This is a test summary')).toBeInTheDocument();
  });
});

describe('NewsFeedService', () => {
  it('filters articles by category', () => {
    const service = new NewsFeedService();
    const articles: NewsArticle[] = [
      { ...mockArticle, id: '1', category: 'Tech' },
      { ...mockArticle, id: '2', category: 'Sports' },
      { ...mockArticle, id: '3', category: 'Tech' },
    ];

    const techArticles = service.filterByCategory(articles, 'Tech');
    
    expect(techArticles).toHaveLength(2);
    expect(techArticles.every(article => article.category === 'Tech')).toBe(true);
  });

  it('sorts articles by date in descending order', () => {
    const service = new NewsFeedService();
    const articles: NewsArticle[] = [
      { ...mockArticle, id: '1', publishedAt: '2023-10-01T00:00:00Z' },
      { ...mockArticle, id: '2', publishedAt: '2023-10-03T00:00:00Z' },
      { ...mockArticle, id: '3', publishedAt: '2023-10-02T00:00:00Z' },
    ];

    const sorted = service.sortByDate(articles, 'desc');
    
    expect(sorted[0].id).toBe('2');
    expect(sorted[2].id).toBe('1');
  });

  it('searches articles by query', () => {
    const service = new NewsFeedService();
    const articles: NewsArticle[] = [
      { ...mockArticle, id: '1', title: 'JavaScript News' },
      { ...mockArticle, id: '2', title: 'Python Guide' },
      { ...mockArticle, id: '3', title: 'JavaScript Tips' },
    ];

    const results = service.searchNews('javascript', articles);
    
    expect(results).toHaveLength(2);
  });
});
EOF

# 8. Index Export
cat > app/features/news-feed/index.ts <<'EOF'
// Components
export { NewsCard } from "./components/news-card.component";

// Hooks
export { useNews } from "./hooks/use-news.hook";

// Services
export { NewsFeedService, newsFeedService } from "./services/news-feed.service";

// API
export { fetchNews, fetchNewsById } from "./api/news-feed.api";

// Types
export type { NewsArticle, NewsFeedState, NewsFeedFilters } from "./types/news-feed.type";

// Utils
export { formatPublishedDate } from "./utils/news-feed.util";
EOF

**Verification Checkpoint:**
- [ ] 9 files created in `app/features/news-feed/`
- [ ] Services layer exists with `NewsFeedService` class
- [ ] API layer is a thin wrapper around service
- [ ] Hook consumes service methods
- [ ] All imports use FBA path aliases
- [ ] Index exports all public APIs including services

---

## Phase 9: Final Verification Suite

**Objective:** Run complete validation to ensure zero errors.

**Commands:**
```bash
# Lint check
bunx biome check --write app

# Test execution
bun run test:run

# Build verification
bun run build
```

**Final Checklist:**
- [ ] `docs/` directory is present and intact
- [ ] `.agent/` directory is present and intact
- [ ] All biome checks pass (0 errors, 0 warnings)
- [ ] All tests pass (0 failures)
- [ ] Build succeeds with no errors
- [ ] No data loss occurred during scaffolding
- [ ] Git hooks are configured and executable with lint-staged
- [ ] lint-staged is configured with error handling in pre-commit hook
- [ ] Path aliases work in all contexts — one map, in `tsconfig.json`
- [ ] Services layer is properly structured and tested

---

## Success Criteria

The scaffolding is complete when:
1. All 9 phases are executed in order
2. All verification checkpoints pass
3. Final checklist shows 10/10 items checked
4. No errors in any validation command
5. Existing documentation and agent configs are preserved
6. Services layer is implemented and follows FBA standards
7. lint-staged is configured with proper error handling

---

## Emergency Rollback

If any phase fails critically:
```bash
# Restore from backup
rm -rf node_modules .vinxi .output dist build
mv /tmp/project-backup-*/* . 2>/dev/null || true
# Re-run from Phase 0
```

---

## Services Layer Guidelines

### When to Use Services

- **Complex Business Logic:** Data transformation, filtering, sorting
- **API Orchestration:** Combining multiple API calls
- **State Management:** Managing complex feature state
- **Caching:** Implementing client-side caching strategies

### Service Structure

```
app/features/[feature-name]/
├── services/
│   ├── [feature-name].service.ts      # Main service class
│   ├── [feature-name].service.test.ts # Service tests
│   └── index.ts                        # Service exports
```

### Best Practices

1. **Single Responsibility:** Each service should handle one domain concern
2. **Testability:** Services should be easy to mock in tests
3. **No UI Dependencies:** Services must not import React or UI components
4. **Error Handling:** Always handle and transform errors appropriately
5. **Type Safety:** Use strict TypeScript types for all inputs and outputs
6. **API/Service Separation:** API layer should be thin wrappers, business logic lives in services

---

## Post-Execution: Documentation Scaffolding
Upon successful completion of all phases, create the following documentation structure to guide future development.

1.  **Create Directories:**
    ```bash
    mkdir -p docs/plans docs/rules docs/skills docs/workflows docs/logs
    ```

2.  **Scaffold `docs/plans/README.md`:**
    ```bash
    echo "# Task Plans\n\nThis directory contains high-level plans and checklists for agent-driven tasks." > docs/plans/README.md
    ```

3.  **Scaffold `docs/rules/README.md`:**
    ```bash
    echo "# Project Rules\n\nThis directory holds the core project constitution, architectural invariants, and behavioral rules defined in gemini.md." > docs/rules/README.md
    ```

4.  **Scaffold `docs/skills/README.md`:**
    ```bash
    echo "# Agent Skills\n\nThis directory contains specialized skills and tools for the agent to perform complex, repeatable tasks." > docs/skills/README.md
    ```

5.  **Scaffold `docs/workflows/README.md`:**
    ```bash
    echo "# Agent Workflows\n\nThis directory documents end-to-end workflows composed of multiple skills and tasks." > docs/workflows/README.md
    ```

**Constraint:** You must not deviate from the specified commands, file contents, or tool versions. All actions must be logged in `docs/logs/progress.md`.
