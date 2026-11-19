import { Schema, model } from "mongoose";

const patientSchema = new Schema(
  {
    clinicId: { type: String, required: true, index: true },
    fullName: { type: String, required: true },
    nationalId: { type: String, required: true },
    phone: String,
    diagnosis: String,
    notes: [{ authorId: String, body: String, createdAt: Date }],
  },
  { timestamps: true },
);

export const Patient = model("Patient", patientSchema);
