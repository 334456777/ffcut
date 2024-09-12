import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import formataddr
import os

# SMTP 服务器设置
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
SENDER_EMAIL = os.getenv('SENDER_EMAIL')  # 使用环境变量获取邮箱
SENDER_PASSWORD = os.getenv('SENDER_PASSWORD')
RECIPIENT_EMAIL = os.getenv('RECIPIENT_EMAIL')

# 邮件内容
email_calculation = f"{SENDER_EMAIL} 1+2"  # 拼接邮箱和"1+2"
subject = email_calculation  # 主题是邮箱和"1+2"
body = ''  # 邮件正文为空

def send_email(subject, body):
    # 邮件设置
    msg = MIMEMultipart()
    msg['From'] = formataddr(('Sender Name', SENDER_EMAIL))
    msg['To'] = RECIPIENT_EMAIL
    msg['Subject'] = subject

    # 邮件正文为空
    msg.attach(MIMEText(body, 'plain'))

    # 连接到 SMTP 服务器
    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.starttls()  # 启用 TLS 加密
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.sendmail(SENDER_EMAIL, RECIPIENT_EMAIL, msg.as_string())

if __name__ == '__main__':
    send_email(subject, body)
