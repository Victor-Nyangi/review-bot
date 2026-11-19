import { useEffect, useState } from "react";

type Note = { _id: string; authorId: string; body: string; createdAt: string };

export function PatientNotes({ patientId, token }: { patientId: string; token: string }) {
  const [notes, setNotes] = useState<Note[]>([]);

  useEffect(() => {
    fetch(`/api/patients/${patientId}`, { headers: { Authorization: `Bearer ${token}` } })
      .then((res) => res.json())
      .then((patient) => setNotes(patient.notes ?? []));
  }, [patientId, token]);

  return (
    <ul className="notes">
      {notes.map((note) => (
        <li key={note._id}>
          <time>{new Date(note.createdAt).toLocaleString()}</time>
          <div className="note-body" dangerouslySetInnerHTML={{ __html: note.body }} />
        </li>
      ))}
    </ul>
  );
}
