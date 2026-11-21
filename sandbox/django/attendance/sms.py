import requests
from django.conf import settings


class SmsGatewayError(Exception):
    pass


def send_sms(phone, message):
    response = requests.post(
        settings.SMS_GATEWAY_URL,
        json={"to": phone, "message": message},
        timeout=10,
    )
    if response.status_code >= 500:
        raise SmsGatewayError(response.text)
    response.raise_for_status()
