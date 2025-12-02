import fs from 'fs';
import path from 'path';
import { describe, it, expect } from 'vitest';

describe('Architecture Constraints', () => {
  it('_applyAction should only be used in allowed files', () => {
    const srcDir = path.resolve(__dirname, '.');
    const allowedFiles = ['useGameAction.ts', 'useGameDispatch.ts', 'useGameSync.ts'];

    function scanDirectory(dir: string) {
      const files = fs.readdirSync(dir);

      files.forEach((file) => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);

        if (stat.isDirectory()) {
          scanDirectory(filePath);
        } else if (file.endsWith('.ts') || file.endsWith('.tsx')) {
          const content = fs.readFileSync(filePath, 'utf-8');
          if (content.includes('_applyAction')) {
            const isAllowed =
              allowedFiles.includes(file) ||
              file.endsWith('.test.ts') ||
              file === 'architecture.test.ts'; // Allow in this test file

            if (!isAllowed) {
              throw new Error(
                `Forbidden usage of _applyAction found in ${filePath}. It should only be used in ${allowedFiles.join(', ')}.`,
              );
            }
          }
        }
      });
    }

    scanDirectory(srcDir);
  });
});
