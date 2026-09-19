class Pss4Item {
  final String text;
  final bool reversed;

  const Pss4Item({required this.text, required this.reversed});
}

const pss4Items = <Pss4Item>[
  Pss4Item(
    text:
        'Felt unable to control the important things in your life',
    reversed: false,
  ),
  Pss4Item(
    text: 'Felt confident about your ability to handle your personal problems',
    reversed: true,
  ),
  Pss4Item(
    text: 'Felt that things were going your way',
    reversed: true,
  ),
  Pss4Item(
    text:
        'Felt difficulties were piling up so high that you could not overcome them',
    reversed: false,
  ),
];

const pss4ScaleLabels = <String>[
  'Never',
  'Almost Never',
  'Sometimes',
  'Fairly Often',
  'Very Often',
];