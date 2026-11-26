// DeepSeek Harness brand wordmark (figma 356:14644, exact extract): whale +
// "deepseek-official" letterforms + HARNESS badge plate in one svg. Native 182x24.
// Ink rides currentColor; the badge text is knocked out in the inverted
// label color so the plate stays legible in both themes.

import type { IconProps } from './icons/props.ts'

/** Display options for the official brand wordmark. */
export interface BrandWordmarkProps extends IconProps {
  /** Whether to include the leading whale mark; defaults to true. */
  includeMark?: boolean | undefined
}

/**
 * Render the full brand wordmark.
 * @param props.size - height in px (default 24; width follows the selected artwork).
 * @param props.className - extra class for layout placement.
 * @param props.includeMark - whether to include the leading whale mark.
 * @returns the wordmark svg (aria-hidden decorative brand art).
 */
export function BrandWordmark({ size = 24, className, includeMark = true }: BrandWordmarkProps) {
  return <svg width={size * 5.5} height={size} viewBox="0 0 132 24" className={className} aria-hidden="true">{includeMark && <circle cx="12" cy="12" r="10" fill="#2563eb"/>}<text x={includeMark ? 27 : 0} y="17" fontSize="17" fontWeight="600" fill="currentColor">OhamLab</text></svg>
}
