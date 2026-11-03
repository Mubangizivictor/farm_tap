/** Victorbee support line (WhatsApp, calls and SMS), same as the phone's help_page.dart. */
export const SUPPORT_WHATSAPP = '+256 793 128 137';
export const supportWhatsAppLink = (text = 'Hello FarmTap, I need help with the web app.') =>
  `https://wa.me/${SUPPORT_WHATSAPP.replace(/\D/g, '')}?text=${encodeURIComponent(text)}`;
