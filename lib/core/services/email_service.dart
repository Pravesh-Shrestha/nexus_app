import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:nexus_app/core/config/email_config.dart';

class EmailService {
  // Setup the SMTP Server using configuration parameters
  SmtpServer _getSmtpServer() {
    return SmtpServer(
      EmailConfig.smtpHost,
      port: EmailConfig.smtpPort,
      ssl: EmailConfig.smtpPort == 465,
      username: EmailConfig.senderEmail,
      password: EmailConfig.senderPassword,
    );
  }

  /// Generic helper to send emails.
  /// Allows easily adding future email triggers (like community invitations, notifications, etc.).
  Future<void> sendEmail({
    required String recipientEmail,
    required String subject,
    required String htmlContent,
  }) async {
    if (EmailConfig.senderEmail == 'YOUR_EMAIL@gmail.com' ||
        EmailConfig.senderPassword == 'YOUR_APP_PASSWORD') {
      debugPrint('Email service warning: SMTP credentials are not configured. Skipping email.');
      return;
    }

    final smtpServer = _getSmtpServer();

    final message = Message()
      ..from = Address(EmailConfig.senderEmail, EmailConfig.senderName)
      ..recipients.add(recipientEmail)
      ..subject = subject
      ..html = htmlContent;

    try {
      await send(message, smtpServer);
      debugPrint('Email successfully sent to $recipientEmail with subject: "$subject".');
    } catch (e) {
      debugPrint('Failed to send email to $recipientEmail. Error: $e');
    }
  }

  /// Sends a welcome email upon successful account registration.
  Future<void> sendWelcomeEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    final html = '''
      <div style="background-color: #0b0c10; color: #ffffff; padding: 40px; font-family: sans-serif; border-radius: 16px; max-width: 600px; margin: 0 auto; border: 1px solid #1f2833;">
        <h2 style="color: #00e5ff; font-size: 28px; margin-bottom: 20px; font-weight: bold; letter-spacing: 1px;">Welcome to Nexus!</h2>
        <p style="font-size: 16px; line-height: 1.6; color: #c5c6c7;">Hi <strong>$recipientName</strong>,</p>
        <p style="font-size: 16px; line-height: 1.6; color: #c5c6c7;">Thank you for registering on <strong>Nexus</strong>. Your gaming profile is all set up, and you're now ready to join communities, coordinate plays, and form the ultimate gaming squads!</p>
        <br/>
        <p style="font-size: 16px; line-height: 1.6; color: #c5c6c7;">See you in the lobby,</p>
        <p style="color: #00e5ff; font-size: 16px; font-weight: bold; margin-top: 5px;">The Nexus Team</p>
      </div>
    ''';

    await sendEmail(
      recipientEmail: recipientEmail,
      subject: 'Welcome to Nexus, $recipientName!',
      htmlContent: html,
    );
  }

  /// Sends a security alert email when a password has been updated.
  Future<void> sendPasswordChangedEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    final html = '''
      <div style="background-color: #0b0c10; color: #ffffff; padding: 40px; font-family: sans-serif; border-radius: 16px; max-width: 600px; margin: 0 auto; border: 1px solid #1f2833;">
        <h2 style="color: #00e5ff; font-size: 28px; margin-bottom: 20px; font-weight: bold; letter-spacing: 1px;">Security Notification</h2>
        <p style="font-size: 16px; line-height: 1.6; color: #c5c6c7;">Hi <strong>$recipientName</strong>,</p>
        <p style="font-size: 16px; line-height: 1.6; color: #c5c6c7;">This is a quick security alert to confirm that the password for your <strong>Nexus Account</strong> was successfully changed.</p>
        <p style="font-size: 14px; line-height: 1.6; color: #ff5555; font-weight: bold; margin-top: 15px;">If you did not make this change, please contact our support team immediately or reset your credentials to secure your profile.</p>
        <br/>
        <p style="font-size: 16px; line-height: 1.6; color: #c5c6c7;">Best regards,</p>
        <p style="color: #00e5ff; font-size: 16px; font-weight: bold; margin-top: 5px;">The Nexus Security Team</p>
      </div>
    ''';

    await sendEmail(
      recipientEmail: recipientEmail,
      subject: 'Your Nexus Password Was Updated',
      htmlContent: html,
    );
  }
}
