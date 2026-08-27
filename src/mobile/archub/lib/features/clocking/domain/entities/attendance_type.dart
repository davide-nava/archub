enum AttendanceType {
  clockIn('CLOCK_IN', 'Entrata'),
  clockOut('CLOCK_OUT', 'Uscita'),
  breakStart('BREAK_START', 'Inizio Pausa'),
  breakEnd('BREAK_END', 'Fine Pausa');

  final String apiValue;
  final String label;

  const AttendanceType(this.apiValue, this.label);

  static AttendanceType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CLOCK_IN':
      case 'IN':
      case 'ENTRATA':
        return AttendanceType.clockIn;
      case 'CLOCK_OUT':
      case 'OUT':
      case 'USCITA':
        return AttendanceType.clockOut;
      case 'BREAK_START':
      case 'BREAK':
      case 'PAUSA':
      case 'INIZIO_PAUSA':
        return AttendanceType.breakStart;
      case 'BREAK_END':
      case 'FINE_PAUSA':
        return AttendanceType.breakEnd;
      default:
        return AttendanceType.clockIn;
    }
  }
}
