import { createContext, useContext, type ReactNode } from 'react';

type PermissionsState = {
  canPublish: boolean;
  isAdmin: boolean;
  role: string;
};

const PermissionsContext = createContext<PermissionsState>({
  canPublish: false,
  isAdmin: false,
  role: 'Content Manager',
});

export function PermissionsProvider({
  value,
  children,
}: {
  value: PermissionsState;
  children: ReactNode;
}) {
  return <PermissionsContext.Provider value={value}>{children}</PermissionsContext.Provider>;
}

export function usePermissions() {
  return useContext(PermissionsContext);
}
