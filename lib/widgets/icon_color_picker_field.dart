import 'package:flutter/material.dart';

/// Sélecteur de couleur libre pour l'icône d'une lipo.
///
/// Contrairement à [ColorPickerField] (qui ne propose que trois
/// couleurs liées à la durée du chronomètre), ce sélecteur permet de
/// choisir n'importe quelle couleur pour l'icône : quelques teintes
/// rapides, un code couleur hexadécimal, ou des curseurs rouge/vert/
/// bleu. Ne rien choisir laisse l'icône avec un dégradé de blancs par
/// défaut.
class IconColorPickerField extends StatefulWidget {
  /// Couleur actuellement choisie, ou `null` pour le dégradé blanc
  /// par défaut.
  final Color? selected;

  /// Appelé avec la couleur choisie, ou `null` pour revenir au
  /// dégradé blanc par défaut.
  final ValueChanged<Color?> onChanged;

  const IconColorPickerField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<IconColorPickerField> createState() => _IconColorPickerFieldState();
}

class _IconColorPickerFieldState extends State<IconColorPickerField> {
  static const List<Color> _quickSwatches = <Color>[
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFF9A825),
    Color(0xFF43A047),
    Color(0xFF00897B),
    Color(0xFF1E88E5),
    Color(0xFF3949AB),
    Color(0xFF8E24AA),
    Color(0xFFD81B60),
    Color(0xFF6D4C41),
  ];

  static const Color _defaultWorkingColor = Color(0xFF9E9E9E);

  late TextEditingController _hexController;
  late Color _workingColor;

  @override
  void initState() {
    super.initState();
    _workingColor = widget.selected ?? _defaultWorkingColor;
    _hexController = TextEditingController(text: _colorToHex(_workingColor));
  }

  @override
  void didUpdateWidget(covariant IconColorPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final Color next = widget.selected ?? _defaultWorkingColor;
      if (next.toARGB32() != _workingColor.toARGB32()) {
        _workingColor = next;
        _hexController.text = _colorToHex(_workingColor);
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  void _applyColor(Color color) {
    setState(() {
      _workingColor = color;
      _hexController.text = _colorToHex(color);
    });
    widget.onChanged(color);
  }

  void _onHexSubmitted(String value) {
    final String cleaned = value.trim().replaceFirst('#', '');
    if (cleaned.length == 6) {
      final int? parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) {
        _applyColor(Color(0xFF000000 | parsed));
        return;
      }
    }
    // Code invalide : on restaure le champ sur la couleur courante.
    _hexController.text = _colorToHex(_workingColor);
  }

  void _updateChannel({int? r, int? g, int? b}) {
    final Color base = _workingColor;
    _applyColor(Color.fromARGB(
      255,
      r ?? (base.r * 255).round(),
      g ?? (base.g * 255).round(),
      b ?? (base.b * 255).round(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDefault = widget.selected == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Dégradé blanc (défaut)'),
              avatar: const Icon(Icons.gradient, size: 18),
              selected: isDefault,
              onSelected: (bool value) {
                if (value) {
                  widget.onChanged(null);
                }
              },
            ),
            for (final Color swatch in _quickSwatches)
              ChoiceChip(
                label: const SizedBox.shrink(),
                avatar: CircleAvatar(backgroundColor: swatch, radius: 10),
                selected:
                    !isDefault && widget.selected!.toARGB32() == swatch.toARGB32(),
                onSelected: (bool value) {
                  if (value) {
                    _applyColor(swatch);
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Ou choisissez une couleur précise :',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            CircleAvatar(
              radius: 16,
              backgroundColor: isDefault ? Colors.grey.shade300 : _workingColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _hexController,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  prefixText: '#',
                  labelText: 'Code hexadécimal',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _onHexSubmitted,
                onEditingComplete: () => _onHexSubmitted(_hexController.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _ColorChannelSlider(
          label: 'R',
          value: (_workingColor.r * 255).round(),
          onChanged: (int v) => _updateChannel(r: v),
        ),
        _ColorChannelSlider(
          label: 'V',
          value: (_workingColor.g * 255).round(),
          onChanged: (int v) => _updateChannel(g: v),
        ),
        _ColorChannelSlider(
          label: 'B',
          value: (_workingColor.b * 255).round(),
          onChanged: (int v) => _updateChannel(b: v),
        ),
      ],
    );
  }
}

class _ColorChannelSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _ColorChannelSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 20, child: Text(label)),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            divisions: 255,
            value: value.toDouble(),
            label: value.toString(),
            onChanged: (double v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 32, child: Text('$value')),
      ],
    );
  }
}
