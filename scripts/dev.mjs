import { spawn } from "node:child_process";

const cliArgs = process.argv.slice(2);
let port = "5173";

for (let index = 0; index < cliArgs.length; index += 1) {
  const argument = cliArgs[index];
  const candidate = argument === "--port" ? cliArgs[index + 1] : argument.startsWith("--port=") ? argument.slice(7) : null;

  if (candidate !== null) {
    if (!/^\d+$/.test(candidate)) {
      console.error(`Invalid port: ${candidate}`);
      process.exit(1);
    }
    port = candidate;
  }
}

const child = spawn(
  "flutter",
  ["run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", port],
  {
    cwd: "lesung_app",
    stdio: "inherit",
    shell: process.platform === "win32",
  },
);

child.on("error", (error) => {
  console.error(`Unable to start Flutter: ${error.message}`);
  process.exit(1);
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exit(code ?? 1);
  }
});
