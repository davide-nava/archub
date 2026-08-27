enum SyncStatus {
  pending('PENDING', 'In attesa'),
  synced('SYNCED', 'Sincronizzato');

  final String value;
  final String label;

  const SyncStatus(this.value, this.label);

  static SyncStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SYNCED':
        return SyncStatus.synced;
      case 'PENDING':
      default:
        return SyncStatus.pending;
    }
  }

  bool get isPending => this == SyncStatus.pending;
  bool get isSynced => this == SyncStatus.synced;
}
