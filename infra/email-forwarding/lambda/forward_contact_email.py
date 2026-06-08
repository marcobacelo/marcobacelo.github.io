import os
from email import policy
from email.message import EmailMessage
from email.parser import BytesParser

import boto3


s3 = boto3.client("s3")
ses = boto3.client("ses")


def _first_header(message, name, default=""):
    value = message.get(name)
    return str(value).strip() if value else default


def _extract_body(message):
    if message.is_multipart():
        for part in message.walk():
            content_type = part.get_content_type()
            disposition = str(part.get("Content-Disposition", ""))
            if content_type == "text/plain" and "attachment" not in disposition:
                return part.get_content()

    content_type = message.get_content_type()
    if content_type == "text/plain":
        return message.get_content()

    return "(Mensagem sem corpo text/plain. Consulte o anexo .eml no bucket S3.)"


def handler(event, _context):
    record = event["Records"][0]
    mail = record["ses"]["mail"]
    message_id = mail["messageId"]

    bucket = os.environ["S3_BUCKET"]
    prefix = os.environ.get("S3_PREFIX", "")
    object_key = f"{prefix}{message_id}"

    raw_email = s3.get_object(Bucket=bucket, Key=object_key)["Body"].read()
    original = BytesParser(policy=policy.default).parsebytes(raw_email)

    original_from = _first_header(original, "From", "remetente desconhecido")
    original_subject = _first_header(original, "Subject", "Sem assunto")
    original_date = _first_header(original, "Date", "data indisponivel")
    original_reply_to = _first_header(original, "Reply-To", original_from)
    body = _extract_body(original)

    forward = EmailMessage()
    forward["From"] = os.environ["FORWARD_FROM"]
    forward["To"] = os.environ["FORWARD_TO"]
    forward["Reply-To"] = original_reply_to
    forward["Subject"] = f"{os.environ['SUBJECT_PREFIX']} {original_subject}"

    forward.set_content(
        "\n".join(
            [
                f"Mensagem recebida em {os.environ['CONTACT_ADDRESS']}.",
                "",
                f"De: {original_from}",
                f"Data: {original_date}",
                f"Objeto S3: s3://{bucket}/{object_key}",
                "",
                "Conteudo:",
                body,
            ]
        )
    )

    forward.add_attachment(
        raw_email,
        maintype="message",
        subtype="rfc822",
        filename=f"{message_id}.eml",
    )

    ses.send_raw_email(
        Source=os.environ["FORWARD_FROM"],
        Destinations=[os.environ["FORWARD_TO"]],
        RawMessage={"Data": forward.as_bytes()},
    )

    return {"messageId": message_id, "forwarded": True}
