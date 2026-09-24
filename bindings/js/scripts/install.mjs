// npm `install` hook: use a prebuilt addon when the package ships one for this
// platform, otherwise compile it from source with cmake-js.
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const prebuilt = join(root, "prebuilds", `${process.platform}-${process.arch}`, "nativeapi.node");
if (existsSync(prebuilt) || existsSync(join(root, "build", "Release", "nativeapi.node"))) {
  process.exit(0);
}
const result = spawnSync("npx", ["cmake-js", "compile"], {
  cwd: root,
  stdio: "inherit",
  shell: process.platform === "win32",
});
process.exit(result.status ?? 1);
