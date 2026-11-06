// Line icons (24 grid, stroke = currentColor), so colour always comes from the theme.

const paths: Record<string, string> = {
  home: 'M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z',
  cow: 'M6 8c-2 0-3-1-3-3 2 0 3 1 4 2m11 1c2 0 3-1 3-3-2 0-3 1-4 2M7 7h10l1 5v4a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4v-4zm3 9h.01M14 16h.01M9 11h.01M15 11h.01',
  milk: 'M9 2h6M10 2v3l-3 4v11a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V9l-3-4V2M7 13h10',
  health: 'M12 21s-7-4.5-9-9.5C1.5 7.5 4 4 7.5 4c2 0 3.5 1 4.5 2.5C13 5 14.5 4 16.5 4 20 4 22.5 7.5 21 11.5 19 16.5 12 21 12 21zM12 9v6M9 12h6',
  money: 'M3 6h18v12H3zM3 10h18M7 15h3',
  workers: 'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM2 21v-1a6 6 0 0 1 6-6h2a6 6 0 0 1 6 6v1M17 3.5a4 4 0 0 1 0 7.5M22 21v-1a6 6 0 0 0-4-5.6',
  farmers: 'M3 17l2-6h10l2 6M5 17h14M7 17v3M17 17v3M8 11l1-4h6l1 4M19 9h2v8',
  settings: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-2.9 1.2V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-2.9-1.2l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.7 1.7 0 0 0 3 14H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.2-2.9l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.7 1.7 0 0 0 10 3V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 2.9 1.2l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1A1.7 1.7 0 0 0 21 10h.1a2 2 0 1 1 0 4H21a1.7 1.7 0 0 0-1.6 1z',
  more: 'M5 12h.01M12 12h.01M19 12h.01',
  menu: 'M4 6h16M4 12h16M4 18h16',
  edit: 'M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z',
  sidebar: 'M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM9 3v18',
  logout: 'M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l-5-5 5-5M5 12h12',
  download: 'M12 3v12M7 10l5 5 5-5M4 21h16',
  print: 'M6 9V3h12v6M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2M6 14h12v7H6z',
  plus: 'M12 5v14M5 12h14',
  search: 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM21 21l-4.3-4.3',
  offline: 'M2 2l20 20M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 5.2-2.8M19 13a10 10 0 0 0-2-1.4M2 8.8a15 15 0 0 1 4.2-2.6M22 8.8A15 15 0 0 0 11 5M12 20h.01',
  alert: 'M12 9v4M12 17h.01M10.3 3.9L2 18a2 2 0 0 0 1.7 3h16.6a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z',
  check: 'M20 6L9 17l-5-5',
  help: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM9.1 9a3 3 0 0 1 5.8 1c0 2-3 3-3 3M12 17h.01',
  sun: 'M12 17a5 5 0 1 0 0-10 5 5 0 0 0 0 10zM12 1v2M12 21v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M1 12h2M21 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4',
  moon: 'M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z',
  chevron: 'M9 18l6-6-6-6',
  lock: 'M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4',
  calendar: 'M3 5h18v16H3zM16 3v4M8 3v4M3 10h18',
  truck: 'M1 4h14v12H1zM15 9h4l3 3v4h-7M5.5 21a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM18.5 21a2 2 0 1 0 0-4 2 2 0 0 0 0 4z',
  close: 'M18 6L6 18M6 6l12 12',
  mail: 'M3 5h18v14H3zM3 6l9 7 9-7',
  drop: 'M12 2.7l5.7 5.6a8 8 0 1 1-11.4 0z',
  feed: 'M4 20h16M6 20V10l6-6 6 6v10M10 20v-6h4v6',
  card: 'M2 5h20v14H2zM2 10h20M6 15h4',
  switch: 'M16 3l4 4-4 4M20 7H4M8 21l-4-4 4-4M4 17h16',
  clock: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 6v6l4 2',
  shield: 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10zM9 12l2 2 4-4',
  flag: 'M4 22V4M4 4h12l-2 4 2 4H4',
  megaphone: 'M3 11v2a1 1 0 0 0 1 1h2l5 4V6L6 10H4a1 1 0 0 0-1 1zM15 9a3 3 0 0 1 0 6M18 6a7 7 0 0 1 0 12',
  key: 'M15 7a4 4 0 1 1-3.9 5H3v3h3v3h3v-3h2.1A4 4 0 0 1 15 7zM16 10h.01',
  phone: 'M7 2h10v20H7zM11 18h2',
  receipt: 'M5 2h14v20l-3-2-2 2-2-2-2 2-2-2-3 2zM9 7h6M9 11h6M9 15h4',
  list: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01',
  refresh: 'M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5',
  eye: 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  tag: 'M20.6 13.4l-7.2 7.2a2 2 0 0 1-2.8 0L2 12V2h10l8.6 8.6a2 2 0 0 1 0 2.8zM7 7h.01',
  map: 'M9 3L3 6v15l6-3 6 3 6-3V3l-6 3zM9 3v15M15 6v15',
  globe: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20',
  sms: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2zM8 10h.01M12 10h.01M16 10h.01',
  pause: 'M6 4h4v16H6zM14 4h4v16h-4z',
  play: 'M6 3l14 9-14 9z',
  copy: 'M9 9h11v11H9zM5 15H4V4h11v1',
  chart: 'M3 3v18h18M7 15v2M11 11v6M15 7v10M19 12v5',
  export: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12',
  whatsapp: 'M3 21l1.7-5A9 9 0 1 1 8 19.3zM9 8c0 4 3 7 7 7l1-2-2-1-1 1c-1.5-.5-2.5-1.5-3-3l1-1-1-2z',
  // AI Intelligence (decision 0025): a spark, plus a chat bubble, a camera and a thermometer.
  spark: 'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8zM19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z',
  chat: 'M21 12a8 8 0 0 1-11.6 7.1L4 21l1.9-5.2A8 8 0 1 1 21 12zM8 11h.01M12 11h.01M16 11h.01',
  camera: 'M4 7h3l2-3h6l2 3h3a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1zM12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z',
  thermo: 'M14 14.8V5a2 2 0 1 0-4 0v9.8a4 4 0 1 0 4 0zM12 11v6',
  trend: 'M3 17l6-6 4 4 8-8M15 7h6v6',
  trash: 'M3 6h18M8 6V4h8v2M6 6l1 15h10l1-15M10 11v6M14 11v6',
  up: 'M12 19V5M5 12l7-7 7 7',
  stop: 'M6 6h12v12H6z',
  thumbUp: 'M7 10v11H3V10zM7 10l4-8a2 2 0 0 1 2 2v4h6a2 2 0 0 1 2 2.3l-1.3 7a2 2 0 0 1-2 1.7H7',
  thumbDown: 'M17 14V3h4v11zM17 14l-4 8a2 2 0 0 1-2-2v-4H5a2 2 0 0 1-2-2.3l1.3-7A2 2 0 0 1 6.3 5H17',
  volume: 'M11 5L6 9H2v6h4l5 4zM15.5 8.5a5 5 0 0 1 0 7M19 5a10 10 0 0 1 0 14',
  share: 'M4 12v8h16v-8M16 6l-4-4-4 4M12 2v13',
  mic: 'M12 15a3 3 0 0 0 3-3V6a3 3 0 0 0-6 0v6a3 3 0 0 0 3 3zM19 11a7 7 0 0 1-14 0M12 18v3',
  image: 'M3 5h18v14H3zM3 16l5-5 4 4 3-3 6 5M9 9h.01',
  file: 'M6 2h8l5 5v15H6zM14 2v5h5M9 13h6M9 17h6',
  pin: 'M12 17v5M8 3h8l-1 6 3 4H6l3-4z',
  translate: 'M4 5h8M8 3v2M6 13c2-1 4-4 4-8M6 9c1 2 3 4 5 5M13 21l4-10 4 10M14.5 18h5',
  zoomIn: 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM21 21l-4.3-4.3M11 8v6M8 11h6',
  zoomOut: 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM21 21l-4.3-4.3M8 11h6',
  scan: 'M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3M4 12h16',
  bell: 'M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 0 1-3.4 0',
  video: 'M3 6h12a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H3zM16 10l5-3v10l-5-3',
  down: 'M6 9l6 6 6-6',
  compare: 'M12 3v18M3 7h6v10H3zM15 7h6v10h-6z',
  bolt: 'M13 2L4 14h7l-1 8 9-12h-7z',
  book: 'M4 19V5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2zM4 19a2 2 0 0 0 2 2h13',
  cloud: 'M7 18a4 4 0 0 1-.6-8A6 6 0 0 1 18 9a4.5 4.5 0 0 1 0 9z',
  pinFill: 'M12 17v5M8 3h8l-1 6 3 4H6l3-4z',
  wifiOff: 'M2 2l20 20M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 5.2-2.8M19 13a10 10 0 0 0-2-1.4M2 8.8a15 15 0 0 1 4.2-2.6M22 8.8A15 15 0 0 0 11 5M12 20h.01',
  link: 'M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1',
};

const apple =
  'M16.4 12.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.3-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9 0 0-2.7-1-2.7-4.1zM13.9 4.9c.7-.9 1.2-2 1-3.2-1 0-2.3.7-3 1.6-.7.8-1.3 2-1.1 3.1 1.1.1 2.3-.6 3.1-1.5z';

export type IconName = keyof typeof paths | 'apple';

export function Icon({ name, className = 'icon', label }: { name: IconName; className?: string; label?: string }) {
  if (name === 'apple') {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-hidden={!label} aria-label={label} role={label ? 'img' : undefined}>
        <path d={apple} />
      </svg>
    );
  }
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden={!label}
      aria-label={label}
      role={label ? 'img' : undefined}
    >
      <path d={paths[name]} />
    </svg>
  );
}
