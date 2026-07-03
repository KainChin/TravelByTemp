import { ReactNode } from 'react';

export function PageTransition({ pageKey, children }: { pageKey: string; children: ReactNode }) {
  return (
    <div key={pageKey} className="admin-page-transition">
      {children}
    </div>
  );
}
