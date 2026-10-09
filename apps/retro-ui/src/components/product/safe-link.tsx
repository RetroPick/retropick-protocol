'use client';

import type { AnchorHTMLAttributes, MouseEvent, ReactNode } from 'react';

type SafeLinkProps = AnchorHTMLAttributes<HTMLAnchorElement> & {
  href: string;
  children: ReactNode;
};

/** Keeps navigation usable in embedded mobile browsers before app hydration. */
export default function SafeLink({ href, children, onClick, target, ...props }: SafeLinkProps) {
  const navigate = (event: MouseEvent<HTMLAnchorElement>) => {
    onClick?.(event);
    if (
      event.defaultPrevented ||
      target ||
      event.button !== 0 ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      href.startsWith('#') ||
      /^https?:\/\//.test(href)
    ) return;

    // Avoid client-router interception in embedded browsers. A regular page
    // load is more reliable than an RSC transition for this demo application.
    event.preventDefault();
    event.stopPropagation();
    window.location.assign(href);
  };

  return <a href={href} onClick={navigate} target={target} {...props}>{children}</a>;
}
