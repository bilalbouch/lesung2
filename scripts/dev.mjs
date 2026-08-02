import { existsSync } from "node:fs";
import { spawn } from "node:child_process";

const appDirectory = "lesung_app";
const cliArgs = process.argv.slice(2);
let port = "5173";

for (let index = 0; index < cliArgs.length; index += 1) {
  const argument = cliArgs[index];
  const candidate =
    argument === "--port"
      ? cliArgs[index + 1]
      : argument.startsWith("--port=")
        ? argument.slice(7)
        : null;

  if (candidate !== null) {
    if (!/^\d+$/.test(candidate)) {
      console.error(`Invalid port: ${candidate}`);
      process.exit(1);
    }
    port = candidate;
  }
}

function runFlutter(args) {
  return new Promise((resolve, reject) => {
    const isWindows = process.platform === "win32";
    const command = isWindows ? (process.env.ComSpec ?? "cmd.exe") : "flutter";
    const commandArgs = isWindows
      ? ["/d", "/s", "/c", ["flutter", ...args].join(" ")]
      : args;
    const child = spawn(command, commandArgs, {
      cwd: appDirectory,
      stdio: "inherit",
    });

    child.on("error", reject);
    child.on("exit", (code, signal) => {
      if (signal) {
        process.kill(process.pid, signal);
        return;
      }
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Flutter exited with code ${code ?? 1}`));
      }
    });
  });
}

async function main() {
  const missingPlatforms = [];
  if (!existsSync(`${appDirectory}/ios`)) missingPlatforms.push("ios");
  if (!existsSync(`${appDirectory}/web`)) missingPlatforms.push("web");

  if (missingPlatforms.length > 0) {
    console.log(`Creating missing Flutter platforms: ${missingPlatforms.join(", ")}`);
    await runFlutter([
      "create",
      `--platforms=${missingPlatforms.join(",")}`,
      ".",
    ]);
  }

  await runFlutter([
    "run",
    "-d",
    "web-server",
    "--web-hostname",
    "0.0.0.0",
    "--web-port",
    port,
  ]);
}

main().catch((error) => {
  console.error(`Unable to start Flutter: ${error.message}`);
  process.exit(1);
});
