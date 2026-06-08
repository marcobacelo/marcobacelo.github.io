import { useState } from "react";

const links = [
  { href: "/", label: "Início" },
  { href: "/sobre", label: "Sobre" },
  { href: "/servicos", label: "Serviços" },
  { href: "/projetos", label: "Projetos" },
  { href: "/contato", label: "Contato" },
] as const;

type Props = {
  currentPath: string;
};

export default function MobileNav({ currentPath }: Props) {
  const [open, setOpen] = useState(false);

  return (
    <div className="md:hidden">
      <button
        type="button"
        className="rounded-lg border border-slate-700 px-3 py-2 text-sm text-slate-200"
        aria-expanded={open}
        aria-controls="mobile-menu"
        onClick={() => setOpen((v) => !v)}
      >
        {open ? "Fechar" : "Menu"}
      </button>
      {open ? (
        <nav
          id="mobile-menu"
          className="absolute left-0 right-0 top-full border-b border-slate-800 bg-royal-950 px-4 py-4 shadow-xl"
        >
          <ul className="space-y-1">
            {links.map((item) => (
              <li key={item.href}>
                <a
                  href={item.href}
                  className={`block rounded-lg px-3 py-2 text-sm font-medium ${
                    currentPath === item.href
                      ? "bg-royal-800 text-white"
                      : "text-slate-300 hover:bg-royal-900"
                  }`}
                  onClick={() => setOpen(false)}
                >
                  {item.label}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      ) : null}
    </div>
  );
}
