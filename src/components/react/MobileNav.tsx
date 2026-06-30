import { useEffect, useRef, useState } from "react";

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

function MenuIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5"
      aria-hidden="true"
    >
      <path d="M4 6h16M4 12h16M4 18h16" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-5 w-5"
      aria-hidden="true"
    >
      <path d="M18 6 6 18M6 6l12 12" />
    </svg>
  );
}

export default function MobileNav({ currentPath }: Props) {
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  useEffect(() => {
    if (!open) return;

    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }

    function handleClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }

    document.addEventListener("keydown", handleKeyDown);
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [open]);

  return (
    <div ref={containerRef} className="md:hidden">
      <button
        type="button"
        className="inline-flex min-h-11 min-w-11 items-center justify-center rounded-lg border border-slate-700 text-slate-200"
        aria-expanded={open}
        aria-controls="mobile-menu"
        aria-label={open ? "Fechar menu" : "Abrir menu"}
        onClick={() => setOpen((v) => !v)}
      >
        {open ? <CloseIcon /> : <MenuIcon />}
      </button>
      {open ? (
        <nav
          id="mobile-menu"
          className="absolute left-0 right-0 top-full max-h-[calc(100dvh-4rem)] overflow-y-auto border-b border-slate-800 bg-royal-950 px-4 py-4 shadow-xl"
        >
          <ul className="space-y-1">
            {links.map((item) => (
              <li key={item.href}>
                <a
                  href={item.href}
                  className={`flex min-h-11 items-center rounded-lg px-3 py-3 text-sm font-medium ${
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
          <a
            href="/contato"
            className="mt-4 flex min-h-11 items-center justify-center rounded-lg bg-royal-accent px-4 py-3 text-sm font-semibold text-white shadow-md shadow-indigo-900/30 transition hover:bg-royal-accent-light"
            onClick={() => setOpen(false)}
          >
            Fale conosco
          </a>
        </nav>
      ) : null}
    </div>
  );
}
