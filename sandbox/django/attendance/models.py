from django.conf import settings
from django.db import models


class School(models.Model):
    name = models.CharField(max_length=200)


class Student(models.Model):
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name="students")
    full_name = models.CharField(max_length=200)
    guardian_phone = models.CharField(max_length=20)
    absence_count = models.PositiveIntegerField(default=0)


class AttendanceRecord(models.Model):
    class Status(models.TextChoices):
        PRESENT = "present"
        ABSENT = "absent"

    school = models.ForeignKey(School, on_delete=models.CASCADE)
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="records")
    day = models.DateField()
    status = models.CharField(max_length=10, choices=Status.choices)
    guardian_notified = models.BooleanField(default=False)
    marked_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["student", "day"], name="one_record_per_student_per_day"),
        ]
