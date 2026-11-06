"use client";

import { useEffect } from "react";
import { ResetIcon } from "./icons";
import { IconTile } from "./ui";

type Props = {
  demo: boolean;
  busy: boolean;
  onCancel: () => void;
  onConfirm: () => void;
};

/** CU-41: reiniciar borra pedidos de verdad, así que se pregunta antes. */
export function ResetDialog({ demo, busy, onCancel, onConfirm }: Props) {
  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape" && !busy) onCancel();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [busy, onCancel]);

  return (
    <div className="absolute inset-0 z-40 grid place-items-center bg-ink/60 p-4">
      <div
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="reset-title"
        aria-describedby="reset-body"
        className="glass rise-in w-full max-w-[520px] rounded-[28px] p-6"
      >
        <div className="flex items-start gap-4">
          <IconTile tone="bad">
            <ResetIcon size={22} />
          </IconTile>
          <div className="min-w-0">
            <h2 id="reset-title" className="text-xl font-semibold tracking-tight">
              ¿Reiniciar el escenario?
            </h2>
            <div id="reset-body" className="mt-2 space-y-2 text-[15px] leading-relaxed text-muted">
              {demo ? (
                <p>En modo demostración solo se reinicia el reloj de este ensayo. No se borra nada.</p>
              ) : (
                <>
                  <p>
                    Se borran <strong className="text-text">todos los pedidos</strong> de las centrales de
                    la demostración, también los que hicieron personas desde su celular. Sus cuentas no
                    se borran.
                  </p>
                  <p>
                    Los drones vuelven a su central con la batería llena; el stock y las geovallas
                    quedan como en la semilla, y el reloj vuelve a la hora real.
                  </p>
                </>
              )}
            </div>
          </div>
        </div>
        <div className="mt-6 flex justify-end gap-2.5">
          <button
            type="button"
            onClick={onCancel}
            disabled={busy}
            className="h-11 rounded-[14px] border border-glass-border bg-glass px-5 text-sm font-semibold text-text transition hover:bg-white/12 active:scale-95 disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-accent"
          >
            Cancelar
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={busy}
            autoFocus
            className="flex h-11 items-center gap-2 rounded-[14px] border border-danger/40 bg-danger/15 px-5 text-sm font-semibold text-danger transition hover:bg-danger/25 active:scale-95 disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-danger"
          >
            {busy ? (
              <span className="size-4 animate-spin rounded-full border-2 border-danger/30 border-t-danger motion-reduce:animate-none" />
            ) : (
              <ResetIcon size={16} />
            )}
            {busy ? "Reiniciando…" : "Reiniciar"}
          </button>
        </div>
      </div>
    </div>
  );
}
