"use client";

import { useEffect } from "react";
import { ResetIcon } from "./icons";
import { Button } from "./ui";

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
    <div className="absolute inset-0 z-50 grid place-items-center bg-ground/70 p-4">
      <div
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="reset-title"
        aria-describedby="reset-body"
        className="surface enter-up w-full max-w-[480px] rounded-xl p-6"
      >
        <h2 id="reset-title" className="text-[19px] font-semibold tracking-[-0.01em]">
          ¿Reiniciar el escenario?
        </h2>
        <div id="reset-body" className="mt-3 space-y-2.5 text-[14px] leading-relaxed text-muted">
          {demo ? (
            <p>En modo demostración solo se reinicia el reloj de este ensayo. No se borra nada.</p>
          ) : (
            <>
              <p>
                Se borran <strong className="font-medium text-text">todos los pedidos</strong> de las
                centrales de la demostración, también los que hicieron personas desde su celular. Sus
                cuentas no se borran.
              </p>
              <p>
                Los drones vuelven a su central con la batería llena; el stock y las geovallas quedan
                como en la semilla, el reloj vuelve a la hora real y se apagan los actores y el caos.
              </p>
            </>
          )}
        </div>
        <div className="mt-6 flex justify-end gap-2">
          <Button tone="quiet" onClick={onCancel} disabled={busy}>
            Cancelar
          </Button>
          <Button tone="danger" onClick={onConfirm} busy={busy}>
            {!busy && <ResetIcon size={16} />}
            {busy ? "Reiniciando…" : "Reiniciar"}
          </Button>
        </div>
      </div>
    </div>
  );
}
