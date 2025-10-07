const EMAIL_DELIVERY_WAIT_MS = 2000;

export interface EmailMessage {
  to: Array<{ address: string }>;
  from: Array<{ address: string }>;
  subject: string;
  html: string;
  text: string;
}

export class MaildevClient {
  private readonly baseUrl: string;

  constructor(maildevUrl: string) {
    this.baseUrl = maildevUrl;
  }

  async clearAllEmails(): Promise<void> {
    await fetch(`${this.baseUrl}/email/all`, { method: "DELETE" });
  }

  async waitForDelivery(): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, EMAIL_DELIVERY_WAIT_MS));
  }

  async getEmails(): Promise<EmailMessage[]> {
    const response = await fetch(`${this.baseUrl}/email`);
    return (await response.json()) as EmailMessage[];
  }

  async getEmailsForAddress(emailAddress: string): Promise<EmailMessage[]> {
    const emails = await this.getEmails();
    return emails.filter((email) =>
      email.to.some((recipient) => recipient.address === emailAddress)
    );
  }

  extractTokenFromEmail(email: EmailMessage): string | null {
    const tokenMatch = email.html.match(/>([a-z0-9]{5}-[a-z0-9]{5})</i);
    return tokenMatch?.[1] ?? null;
  }
}
