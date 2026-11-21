from celery import shared_task

from .models import AttendanceRecord
from .sms import send_sms, SmsGatewayError


@shared_task(bind=True, autoretry_for=(SmsGatewayError,), retry_backoff=True, max_retries=5)
def notify_guardian_of_absence(self, record_id):
    record = AttendanceRecord.objects.select_related("student").get(pk=record_id)
    student = record.student

    student.absence_count = student.absence_count + 1
    student.save(update_fields=["absence_count"])

    send_sms(
        student.guardian_phone,
        f"{student.full_name} was marked absent on {record.day:%d %b}.",
    )

    record.guardian_notified = True
    record.save(update_fields=["guardian_notified"])
