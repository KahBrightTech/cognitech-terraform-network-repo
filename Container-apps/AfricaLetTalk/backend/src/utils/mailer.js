const nodemailer = require('nodemailer');

const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:3000';

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
    }
});

const sendVerificationEmail = async (toEmail, name, token) => {
    const verifyUrl = `${FRONTEND_URL}/verify-email?token=${token}`;

    const html = `
    <div style="max-width:520px;margin:0 auto;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#fff;border-radius:12px;overflow:hidden;border:1px solid #eee;">
      <div style="background:linear-gradient(135deg,#E07A2F,#D4A373);padding:32px 24px;text-align:center;">
        <h1 style="color:#fff;margin:0;font-size:24px;">LetsConnect<span style="font-weight:400;">Afrika</span></h1>
      </div>
      <div style="padding:32px 24px;">
        <h2 style="margin:0 0 12px;font-size:20px;color:#1A1A2E;">Welcome, ${name}!</h2>
        <p style="color:#555;font-size:15px;line-height:1.6;margin:0 0 24px;">
          Thanks for joining LetsConnect. Please verify your email address to activate your account and start connecting with the community.
        </p>
        <div style="text-align:center;margin:24px 0;">
          <a href="${verifyUrl}" style="display:inline-block;background:#E07A2F;color:#fff;text-decoration:none;padding:14px 36px;border-radius:10px;font-size:15px;font-weight:600;">
            Verify My Email
          </a>
        </div>
        <p style="color:#999;font-size:13px;line-height:1.5;">
          If the button doesn't work, copy and paste this link into your browser:<br>
          <a href="${verifyUrl}" style="color:#E07A2F;word-break:break-all;">${verifyUrl}</a>
        </p>
      </div>
      <div style="background:#F9FAFB;padding:16px 24px;text-align:center;">
        <p style="color:#999;font-size:12px;margin:0;">© 2026 LetsConnectAfrika. All rights reserved.</p>
      </div>
    </div>`;

    await transporter.sendMail({
        from: `"LetsConnect" <${process.env.SMTP_USER || 'noreply@letsconnect.com'}>`,
        to: toEmail,
        subject: 'Verify your LetsConnect account',
        html
    });
};

module.exports = { sendVerificationEmail };
