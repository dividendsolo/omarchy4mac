import { defineConfig } from "vitest/config";
import NoSkipReporter from "./vitest.no-skip";

export default defineConfig({
  test: {
    reporters: ["default", new NoSkipReporter()],
  },
});
