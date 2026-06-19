/// Standard brew type options shown in batch/idea creation.
///
/// The app still stores the type as a plain string, so older imported values
/// stay compatible even if the list changes later.
const standardBrewTypes = <String>[
  'Wine',
  'Mead',
  'Pyment',
  'Melomel',
  'Cyser',
  'Metheglin',
  'Bochet',
  'Braggot',
  'Hydromel',
  'Acerglyn',
  'Sake',
  'Cider',
  'Perry',
  'Beer',
  'Other',
];

/// Keeps old/custom imported values visible in the dropdown.
List<String> brewTypeOptionsFor(String selectedType) {
  if (selectedType.isEmpty || standardBrewTypes.contains(selectedType)) {
    return standardBrewTypes;
  }
  return [selectedType, ...standardBrewTypes];
}
