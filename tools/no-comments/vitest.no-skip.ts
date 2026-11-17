import type { Reporter, TestModule, Vitest } from "vitest/node";

export default class NoSkipReporter implements Reporter {
  private filtered = false;

  onInit(vitest: Vitest) {
    this.filtered = Boolean(vitest.config.testNamePattern);
  }

  onTestRunEnd(testModules: ReadonlyArray<TestModule>) {
    if (this.filtered) return;
    const skipped: string[] = [];
    for (const mod of testModules) {
      for (const test of mod.children.allTests()) {
        if (test.result().state === "skipped") skipped.push(`${mod.moduleId}: ${test.fullName}`);
      }
    }
    if (skipped.length === 0) return;
    console.error(
      `\nFAIL: ${skipped.length} skipped test(s). A skip is a failure here; fix the cause, change the test, or delete it:`,
    );
    for (const name of skipped) console.error(`  - ${name}`);
    process.exitCode = 1;
  }
}
