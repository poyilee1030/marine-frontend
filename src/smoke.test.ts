// 只用來證明「npm test → Vitest」這條管線是通的。
// step-2 有了 view.test.ts 之後刪掉（見 ROADMAP step-2）。
import { describe, expect, it } from "vitest";

describe("smoke", () => {
  it("Vitest 能跑 TypeScript 測試", () => {
    const add = (a: number, b: number): number => a + b;
    expect(add(1, 2)).toBe(3);
  });
});
