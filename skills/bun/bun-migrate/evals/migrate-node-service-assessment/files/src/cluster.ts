import cluster from "node:cluster";
import { cpus } from "node:os";

if (cluster.isPrimary) {
  for (let i = 0; i < cpus().length; i++) cluster.fork();
} else {
  await import("./index");
}
