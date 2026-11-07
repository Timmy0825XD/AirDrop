"use client";

import { useId, useState, type FormEvent, type ReactNode } from "react";
import { Wordmark } from "./BrandMark";
import { AlertIcon, ArrowRightIcon, EyeIcon } from "./icons";
import { Button } from "./ui";

type Props = {
  onLogin: (email: string, password: string) => Promise<void>;
};

function Field({
  label,
  id,
  trailing,
  children,
}: {
  label: string;
  id: string;
  trailing?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div>
      <label htmlFor={id} className="text-[13px] font-medium text-muted">
        {label}
      </label>
      <div className="mt-2 flex h-11 items-center rounded-lg border border-line bg-panel transition-[border-color,box-shadow] duration-150 focus-within:border-accent focus-within:shadow-[0_0_0_3px_rgb(122_167_255/0.18)] hover:border-line-strong">
        {children}
        {trailing}
      </div>
    </div>
  );
}

/**
 * La entrada a la consola: una columna, el formulario y nada más. Solo el
 * administrador entra; quien quiera ensayar sin backend tiene la demostración.
 */
export function LoginForm({ onLogin }: Props) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [visible, setVisible] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const emailId = useId();
  const passwordId = useId();

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await onLogin(email, password);
    } catch (failure) {
      setError(failure instanceof Error ? failure.message : "No se pudo iniciar sesión.");
      setBusy(false);
    }
  }

  const input =
    "h-full min-w-0 flex-1 bg-transparent px-3.5 text-[15px] text-text outline-none placeholder:text-faint";

  return (
    <main className="flex min-h-dvh flex-col bg-ground">
      <header className="px-6 py-6 sm:px-10">
        <Wordmark />
      </header>

      <div className="flex flex-1 items-center justify-center px-6 pb-16">
        <form onSubmit={submit} className="enter-up w-full max-w-[380px]" noValidate={false}>
          <h1 className="text-[28px] font-semibold leading-tight tracking-[-0.025em]">
            Consola de simulación
          </h1>
          <p className="mt-2 text-[15px] leading-relaxed text-muted">
            Entra con la cuenta del administrador para seguir los vuelos y lanzar eventos.
          </p>

          <div className="mt-8 space-y-5">
            <Field label="Correo electrónico" id={emailId}>
              <input
                id={emailId}
                type="email"
                required
                autoComplete="username"
                placeholder="nombre@correo.com"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                className={input}
              />
            </Field>
            <Field
              label="Contraseña"
              id={passwordId}
              trailing={
                <button
                  type="button"
                  onClick={() => setVisible((value) => !value)}
                  aria-label={visible ? "Ocultar la contraseña" : "Mostrar la contraseña"}
                  aria-pressed={visible}
                  className={`mr-1.5 grid size-8 place-items-center rounded-md transition-colors hover:bg-hover ${visible ? "text-accent" : "text-faint hover:text-text"}`}
                >
                  <EyeIcon size={17} />
                </button>
              }
            >
              <input
                id={passwordId}
                type={visible ? "text" : "password"}
                required
                autoComplete="current-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className={input}
              />
            </Field>
          </div>

          {error && (
            <p
              role="alert"
              className="enter-up mt-5 flex items-start gap-2.5 rounded-lg border border-danger/40 bg-danger/8 px-3.5 py-3 text-[14px] text-danger"
            >
              <AlertIcon size={17} className="mt-px shrink-0" />
              {error}
            </p>
          )}

          <Button type="submit" busy={busy} className="mt-7 w-full">
            {busy ? "Entrando…" : "Entrar"}
            {!busy && <ArrowRightIcon size={17} />}
          </Button>

          <div className="mt-8 border-t border-line pt-6 text-[14px] text-muted">
            ¿Sin backend a mano?{" "}
            <a
              href="?demo=1"
              className="font-medium text-text underline decoration-line-strong underline-offset-4 transition-colors hover:decoration-accent"
            >
              Abrir la demostración
            </a>
          </div>
        </form>
      </div>

      <footer className="flex justify-between px-6 py-5 text-[12px] text-faint sm:px-10">
        <span>Valledupar, Cesar</span>
        <span>Solo administradores</span>
      </footer>
    </main>
  );
}
