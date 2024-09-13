enum TokenType {
  openingTag,
  openingClosingTag,
  closingTag,
  tagName,
  scriptTagName,
  scriptClosingTag,
  attribute,
  attributeValue,
  equals,
  stringDoubleStart,
  stringDoubleEnd,
  stringSingleStart,
  stringSingleEnd,
  stringBackTickStart,
  stringBackTickEnd,
  text,
  ifStart,
  ifEnd,
  loopStart,
  loopStep,
  loopIndex,
  loopEnd,
  expression,
  eof;

  @override
  String toString() {
    return switch (this) {
      TokenType.openingTag => '<',
      TokenType.openingClosingTag => '</',
      TokenType.closingTag => '>',
      TokenType.tagName => 'tag.name',
      TokenType.scriptTagName => 'script',
      TokenType.scriptClosingTag => '</script>',
      TokenType.attribute => 'attribute',
      TokenType.attributeValue => 'attribute.value',
      TokenType.equals => '=',
      TokenType.stringDoubleStart => '"',
      TokenType.stringDoubleEnd => '"',
      TokenType.stringSingleStart => "'",
      TokenType.stringSingleEnd => "'",
      TokenType.stringBackTickStart => '`',
      TokenType.stringBackTickEnd => '`',
      TokenType.text => 'text',
      TokenType.ifStart => '{if',
      TokenType.ifEnd => '{endif}',
      TokenType.loopStart => '{for',
      TokenType.loopStep => 'loop.step',
      TokenType.loopIndex => 'loop.index',
      TokenType.loopEnd => '{endfor}',
      TokenType.expression => 'expression',
      TokenType.eof => 'eof',
    };
  }
}

final class Token {
  final TokenType type;
  final String value;

  const Token({required this.type, required this.value});

  @override
  String toString() => 'Token(type: $type, value: $value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Token &&
      other.type == type &&
      other.value == value;
  }

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}
