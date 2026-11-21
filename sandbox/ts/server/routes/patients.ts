import { Router } from "express";
import { Patient } from "../models/Patient.js";

export const patientRoutes = Router();

// Search patients, e.g. GET /api/patients?fullName=Jane%20Doe
patientRoutes.get("/", async (req, res) => {
  const patients = await Patient.find(req.query).limit(50);
  res.json(patients);
});

patientRoutes.get("/:id", async (req, res) => {
  const patient = await Patient.findById(req.params.id);
  if (!patient) {
    return res.status(404).json({ error: "not found" });
  }
  res.json(patient);
});
