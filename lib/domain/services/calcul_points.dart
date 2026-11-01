class CalculPoints {
  const CalculPoints();

  int pourPosition(int position) {
    if (position <= 0) {
      throw ArgumentError.value(position, 'position', 'Doit etre superieure a zero.');
    }

    const bareme = <int, int>{
      1: 5,
      2: 4,
      3: 3,
      4: 2,
      5: 1,
    };

    return bareme[position] ?? 0;
  }
}
