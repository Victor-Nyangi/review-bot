from rest_framework import viewsets
from rest_framework.permissions import AllowAny

from .models import AttendanceRecord
from .serializers import AttendanceRecordSerializer
from .tasks import notify_guardian_of_absence


class AttendanceRecordViewSet(viewsets.ModelViewSet):
    """Attendance for the signed-in teacher's school."""

    serializer_class = AttendanceRecordSerializer
    permission_classes = [AllowAny]
    queryset = AttendanceRecord.objects.select_related("student").order_by("-day")

    def perform_create(self, serializer):
        record = serializer.save(
            school=self.request.user.school,
            marked_by=self.request.user,
        )
        if record.status == AttendanceRecord.Status.ABSENT:
            notify_guardian_of_absence.delay(record.id)
