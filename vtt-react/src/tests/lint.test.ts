import { describe, test, expect } from 'vitest';
import fs from 'fs';
import path from 'path';

// Forbidden strings that caused bugs
const FORBIDDEN_STRINGS = ["'red'", '"red"', "'yellow'", '"yellow"', "'blue'", '"blue"'];

function scanFile(filePath: string) {
  const content = fs.readFileSync(filePath, 'utf-8');
  FORBIDDEN_STRINGS.forEach((str) => {
    if (content.includes(str)) {
      throw new Error(`Found forbidden string ${str} in ${filePath}`);
    }
  });
}

function scanDir(dir: string) {
  const files = fs.readdirSync(dir);
  files.forEach((file) => {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      if (file !== 'node_modules' && file !== 'dist' && file !== '.git') {
        scanDir(fullPath);
      }
    } else if (file.endsWith('.ts') || file.endsWith('.tsx')) {
      // Skip this test file itself
      if (!fullPath.endsWith('lint.test.ts')) {
        scanFile(fullPath);
      }
    }
  });
}

describe('Linting', () => {
  test('No hardcoded lowercase resource types', () => {
    const rootDir = path.resolve(__dirname, '..');
    expect(() => scanDir(rootDir)).not.toThrow();
  });
});
