import express, { Request, Response } from "express";
import dotenv from 'dotenv'
dotenv.config({ path: '../../../.env' })

const app = express();
app.use(express.json());

app.get("/health", (_req: Request, res: Response) => {
  res.json({ ok: true });
});

const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`);
});
