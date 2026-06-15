/// Brewing-related gravity calculations.
///
/// Keep formulas here so UI code never needs to know the ABV equation.
class GravityCalculator {
  /// Standard homebrew approximation for alcohol by volume.
  static double? abv(double? og, double? fg) {
    if (og == null || fg == null || og <= 0 || fg <= 0) return null;
    return (og - fg) * 131.25;
  }
}
