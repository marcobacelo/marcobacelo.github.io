export const site = {
  name: "Royal Software Engineering",
  shortName: "Royal SE",
  tagline:
    "Engenharia de software com foco em produto, nuvem e entrega contínua.",
  url: "https://marcobacelo.github.io",
  locale: "pt-BR",
  email: "contato@royalsoftwareengineering.com.br",
  github: "https://github.com/RoyalSoftwareEngineering",
} as const;

export const nav = [
  { href: "/", label: "Início" },
  { href: "/sobre", label: "Sobre" },
  { href: "/servicos", label: "Serviços" },
  { href: "/projetos", label: "Projetos" },
  { href: "/contato", label: "Contato" },
] as const;

export const services = [
  {
    title: "Desenvolvimento de produto",
    description:
      "APIs, interfaces e integrações: do MVP à produção, com contratos claros e testes automatizados.",
  },
  {
    title: "Nuvem e DevOps",
    description:
      "AWS, integração e entrega contínuas, infraestrutura como código e implantação segura com custo consciente.",
  },
  {
    title: "Arquitetura e consultoria",
    description:
      "Revisão de stack, segurança operacional e roadmaps técnicos alinhados ao negócio.",
  },
] as const;

export const projects = [
  {
    name: "Whiskeria CRM",
    description:
      "CRM para varejo pet: API NestJS, interface Next.js, DynamoDB e runtime EC2 na AWS.",
    tags: ["NestJS", "Next.js", "AWS", "DynamoDB"],
    url: "https://whiskeria.niteroi.royalsoftwareengineering.com.br",
  },
] as const;
