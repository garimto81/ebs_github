// Player entity stub. Full Freezed DTO definition in Phase C TDD.
// See DATA-02 §Player entity.

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.stack,
  });

  final int id;
  final String name;
  final String countryCode;
  final int stack;
}
