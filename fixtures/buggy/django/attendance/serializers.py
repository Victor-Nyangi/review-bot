from rest_framework import serializers

from .models import AttendanceRecord


class AttendanceRecordSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source="student.full_name", read_only=True)
    guardian_phone = serializers.CharField(source="student.guardian_phone", read_only=True)

    class Meta:
        model = AttendanceRecord
        fields = ["id", "student", "student_name", "guardian_phone", "day", "status"]
