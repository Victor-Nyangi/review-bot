import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";

export interface AuthedRequest extends Request {
  user?: { id: string; clinicId: string; role: "clinician" | "admin" };
}

export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: "unauthenticated" });
  }
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET as string) as AuthedRequest["user"];
    return next();
  } catch {
    return res.status(401).json({ error: "unauthenticated" });
  }
}
