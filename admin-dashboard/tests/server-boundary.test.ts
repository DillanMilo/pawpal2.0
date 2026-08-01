import { readFileSync } from 'node:fs';
import { globSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

describe('server-only credential boundary', () => {
  it('does not reference the service-role key from any client component', () => {
    const clientFiles = globSync(['app/**/*.tsx', 'app/**/*.ts'], { cwd: process.cwd() })
      .filter((path) => readFileSync(path, 'utf8').startsWith("'use client'"));
    for (const path of clientFiles) {
      expect(readFileSync(path, 'utf8')).not.toContain('SUPABASE_SERVICE_ROLE_KEY');
    }
  });

  it('keeps every service-role access behind server-only imports', () => {
    const serverFiles = globSync(['lib/**/*.ts'], { cwd: process.cwd() })
      .filter((path) => readFileSync(path, 'utf8').includes('SUPABASE_SERVICE_ROLE_KEY'));
    expect(serverFiles).toEqual(['lib/env.ts', 'lib/supabase.ts']);
    for (const path of serverFiles) {
      expect(readFileSync(path, 'utf8')).toContain("import 'server-only'");
    }
  });

  it('collapses dashboard and account grids at the mobile breakpoint', () => {
    const css = readFileSync('app/globals.css', 'utf8');
    expect(css).toContain('@media (max-width: 760px)');
    expect(css).toContain('.dashboard-grid, .detail-grid { grid-template-columns: 1fr; }');
    expect(css).toContain('.table-wrap { overflow-x: auto; }');
  });
});
