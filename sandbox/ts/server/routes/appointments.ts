import { Router } from "express";
import type { AuthedRequest } from "../middleware/requireAuth.js";
import { Patient } from "../models/Patient.js";

export const appointmentRoutes = Router();

appointmentRoutes.get("/today", async (req: AuthedRequest, res) => {
  const patients = await Patient.find({ clinicId: req.user!.clinicId })
    .select("fullName phone")
    .limit(100);
  res.json(patients);
});
