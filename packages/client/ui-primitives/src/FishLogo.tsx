import type { IconProps } from './icons/props.ts'
export function FishLogo({ size = 24, className }: IconProps) {
  return <svg width={size} height={size} viewBox="0 0 24 24" className={className} aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#2563eb"/><path d="M5 12 Q10 5 16 12 Q10 19 5 12 M16 12 L20 8 L20 16 Z" fill="white"/><circle cx="8" cy="11" r="1" fill="#2563eb"/></svg>
}
