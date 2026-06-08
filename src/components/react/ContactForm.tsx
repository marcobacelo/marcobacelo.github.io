import { useState, type FormEvent } from "react";

const EMAIL = "contato@royalsoftwareengineering.com.br";

export default function ContactForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [sent, setSent] = useState(false);

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const subject = encodeURIComponent(`Contato pelo site — ${name}`);
    const body = encodeURIComponent(
      `Nome: ${name}\nE-mail: ${email}\n\n${message}`,
    );
    window.location.href = `mailto:${EMAIL}?subject=${subject}&body=${body}`;
    setSent(true);
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="name" className="mb-1 block text-sm font-medium text-slate-300">
          Nome
        </label>
        <input
          id="name"
          name="name"
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="w-full rounded-lg border border-slate-700 bg-royal-900 px-4 py-2.5 text-white outline-none ring-royal-accent focus:ring-2"
        />
      </div>
      <div>
        <label htmlFor="email" className="mb-1 block text-sm font-medium text-slate-300">
          E-mail
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full rounded-lg border border-slate-700 bg-royal-900 px-4 py-2.5 text-white outline-none ring-royal-accent focus:ring-2"
        />
      </div>
      <div>
        <label htmlFor="message" className="mb-1 block text-sm font-medium text-slate-300">
          Mensagem
        </label>
        <textarea
          id="message"
          name="message"
          required
          rows={5}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          className="w-full resize-y rounded-lg border border-slate-700 bg-royal-900 px-4 py-2.5 text-white outline-none ring-royal-accent focus:ring-2"
        />
      </div>
      <button
        type="submit"
        className="w-full rounded-lg bg-royal-accent px-4 py-3 text-sm font-semibold text-white transition hover:bg-royal-accent-light sm:w-auto"
      >
        Enviar mensagem
      </button>
      {sent ? (
        <p className="text-sm text-slate-400" role="status">
          Seu cliente de e-mail deve abrir em instantes. Caso contrário, escreva para{" "}
          <a href={`mailto:${EMAIL}`} className="text-royal-accent-light underline">
            {EMAIL}
          </a>
          .
        </p>
      ) : null}
    </form>
  );
}
