/// Lifecycle states for a wine/mead batch.
///
/// `idea` items live on the Ideas tab. Every other status appears on the
/// completed/active batch list and can be rated.
enum BrewStatus { idea, fermenting, secondary, aging, bottled, finished }

extension BrewStatusLabel on BrewStatus {
  String get label => switch (this) {
        BrewStatus.idea => 'Ötlet',
        BrewStatus.fermenting => 'Erjed',
        BrewStatus.secondary => 'Másodlagos',
        BrewStatus.aging => 'Érlelődik',
        BrewStatus.bottled => 'Palackozva',
        BrewStatus.finished => 'Elfogyott',
      };
}

/// Backward-compatible JSON parser.
///
/// Older prototypes used `planned` for ideas, so this keeps existing local
/// saves and seed files from breaking when the app evolves.
BrewStatus statusFromJson(dynamic value) {
  if (value == 'planned') return BrewStatus.idea;
  return BrewStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => BrewStatus.fermenting,
  );
}
