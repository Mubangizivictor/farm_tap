/** Full-screen loader: the FarmTap mark turning, with a short line of text. */
export function Loading({ text = 'Opening FarmTap…' }: { text?: string }) {
  return (
    <div className="center-page">
      <div className="logo-loader lg" role="status" aria-live="polite">
        <div className="logo-mark spin-logo" aria-hidden />
        <span className="muted">{text}</span>
      </div>
    </div>
  );
}
