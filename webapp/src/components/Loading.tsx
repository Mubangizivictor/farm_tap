export function Loading({ text = 'Opening FarmTap…' }: { text?: string }) {
  return (
    <div className="center-page">
      <div className="stack" style={{ alignItems: 'center' }}>
        <div className="logo-mark lg spin-slow" aria-hidden />
        <div className="row muted">
          <div className="spinner" aria-hidden />
          <span>{text}</span>
        </div>
      </div>
    </div>
  );
}
