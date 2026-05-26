export interface Region {
  id: string;
  displayName: string;
  city: string;
  group: 'asia' | 'australia';
  ip: string;
  pingUrl: string;
  wsUrl: string;
  storageAccountName: string;
  blobUrl?: string;
}
