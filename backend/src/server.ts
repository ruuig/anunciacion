import { createApp } from "./app";
import { loadEnv } from "./config/env";

const env = loadEnv();
const app = createApp();
const port = env.PORT || 3000;

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 API running on http://0.0.0.0:${port}`);
});