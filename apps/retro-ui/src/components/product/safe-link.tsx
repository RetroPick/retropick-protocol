'use client';

import type { AnchorHTMLAttributes, MouseEvent, ReactNode } from 'react';
import { navigate } from '@/lib/next-compat';

type SafeLinkProps = AnchorHTMLAttributes<HTMLAnchorElement> & {
  href: string;
  children: ReactNode;
};

/** Keeps navigation usable in embedded mobile browsers before app hydration. */
export default function SafeLink({ href, children, onClick, target, ...props }: SafeLinkProps) {
  const handleClick = (event: MouseEvent<HTMLAnchorElement>) => {
    onClick?.(event);
    if (
      event.defaultPrevented ||
      (target && target !== '_self') ||
      props.download !== undefined ||
      event.button !== 0 ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      href.startsWith('#') ||
      new URL(href, window.location.href).origin !== window.location.origin ||
      !['http:', 'https:'].includes(new URL(href, window.location.href).protocol)
    ) return;

    event.preventDefault();
    navigate(href);
    window.scrollTo({ top: 0 });
  };

  return <a href={href} onClick={handleClick} target={target} {...props}>{children}</a>;
}
