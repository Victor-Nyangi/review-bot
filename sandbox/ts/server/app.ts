import express from "express";
import mongoose from "mongoose";
import { requireAuth } from "./middleware/requireAuth.js";
import { appointmentRoutes } from "./routes/appointments.js";
import { patientRoutes } from "./routes/patients.js";

const app = express();
app.use(express.json());

app.use("/api/appointments", requireAuth, appointmentRoutes);
app.use("/api/patients", patientRoutes);

app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: "internal error" });
});

await mongoose.connect(process.env.MONGO_URL as string);
app.listen(Number(process.env.PORT ?? 4000));
