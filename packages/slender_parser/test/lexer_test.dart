import 'package:slender_parser/slender_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Lexer', () {
    test('should return a list of tokens', () {
      final lexer = Lexer(content: '<div></div>');
      final tokens = lexer.tokens.toList();
      expect(tokens.length, 7);
      expect(
        tokens,
        equals([
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.openingClosingTag, value: '</'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.eof, value: ''),
        ]),
      );
    });

    test('should return a list of tokens with attributes', () {
      final lexer = Lexer(content: '<div class="container"></div>');
      final tokens = lexer.tokens.toList();
      expect(tokens.length, 12);
      expect(
        tokens,
        equals([
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.attribute, value: 'class'),
          const Token(type: TokenType.equals, value: '='),
          const Token(type: TokenType.stringDoubleStart, value: '"'),
          const Token(type: TokenType.attributeValue, value: 'container'),
          const Token(type: TokenType.stringDoubleEnd, value: '"'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.openingClosingTag, value: '</'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.eof, value: ''),
        ]),
      );
    });

    test(
      'should return a list of tokens with attribute expression values',
      () {
        final lexer = Lexer(content: '<div class={"red"}>RED</div>');
        final tokens = lexer.tokens.toList();
        expect(tokens.length, 11);
        expect(
          tokens,
          equals([
            const Token(type: TokenType.openingTag, value: '<'),
            const Token(type: TokenType.tagName, value: 'div'),
            const Token(type: TokenType.attribute, value: 'class'),
            const Token(type: TokenType.equals, value: '='),
            const Token(type: TokenType.expression, value: '"red"'),
            const Token(type: TokenType.closingTag, value: '>'),
            const Token(type: TokenType.text, value: 'RED'),
            const Token(type: TokenType.openingClosingTag, value: '</'),
            const Token(type: TokenType.tagName, value: 'div'),
            const Token(type: TokenType.closingTag, value: '>'),
            const Token(type: TokenType.eof, value: ''),
          ]),
        );
      },
    );

    test('should return a list of tokens with text', () {
      final lexer = Lexer(content: '<div>Hello, World!</div>');
      final tokens = lexer.tokens.toList();
      expect(tokens.length, 8);
      expect(
        tokens,
        equals([
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.text, value: 'Hello, World!'),
          const Token(type: TokenType.openingClosingTag, value: '</'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.eof, value: ''),
        ]),
      );
    });

    test('should return a list of tokens with expressions', () {
      final lexer = Lexer(content: '<div>{if true}Hello, World!{endif}</div>');
      final tokens = lexer.tokens.toList();
      expect(tokens.length, 11);
      expect(
        tokens,
        equals([
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.ifStart, value: '{if'),
          const Token(type: TokenType.expression, value: 'true'),
          const Token(type: TokenType.text, value: 'Hello, World!'),
          const Token(type: TokenType.ifEnd, value: '{endif}'),
          const Token(type: TokenType.openingClosingTag, value: '</'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.eof, value: ''),
        ]),
      );
    });

    test('should parse script tag content as text', () {
      final lexer = Lexer(
          content: '<script lang="js">console.log("Hello, World!")</script>');
      final tokens = lexer.tokens.toList();
      expect(tokens.length, 11);
      expect(
        tokens,
        equals([
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.scriptTagName, value: 'script'),
          const Token(type: TokenType.attribute, value: 'lang'),
          const Token(type: TokenType.equals, value: '='),
          const Token(type: TokenType.stringDoubleStart, value: '"'),
          const Token(type: TokenType.attributeValue, value: 'js'),
          const Token(type: TokenType.stringDoubleEnd, value: '"'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(
              type: TokenType.text, value: 'console.log("Hello, World!")'),
          const Token(type: TokenType.scriptClosingTag, value: '</script>'),
          const Token(type: TokenType.eof, value: ''),
        ]),
      );
    });

    test('should parse multiple tags', () {
      final lexer = Lexer(content: '<div></div><span></span>');
      final tokens = lexer.tokens.toList();
      expect(tokens.length, 13);
      expect(
        tokens,
        equals([
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.openingClosingTag, value: '</'),
          const Token(type: TokenType.tagName, value: 'div'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.tagName, value: 'span'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.openingClosingTag, value: '</'),
          const Token(type: TokenType.tagName, value: 'span'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.eof, value: ''),
        ]),
      );
    });

    test('should parse multiple tags with script tag', () {
      const content = '''
        <script lang="dart">
           print("Hello, World!"); 
        </script>
        
        <h1>Hello World!</h1>
      ''';
      final lexer = Lexer(content: content);
      final tokens = lexer.tokens.toList();
      expect(tokens.length, 18);
      expect(
        tokens,
        equals([
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.scriptTagName, value: 'script'),
          const Token(type: TokenType.attribute, value: 'lang'),
          const Token(type: TokenType.equals, value: '='),
          const Token(type: TokenType.stringDoubleStart, value: '"'),
          const Token(type: TokenType.attributeValue, value: 'dart'),
          const Token(type: TokenType.stringDoubleEnd, value: '"'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.text, value: 'print("Hello, World!");'),
          const Token(type: TokenType.scriptClosingTag, value: '</script>'),
          const Token(type: TokenType.openingTag, value: '<'),
          const Token(type: TokenType.tagName, value: 'h1'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.text, value: 'Hello World!'),
          const Token(type: TokenType.openingClosingTag, value: '</'),
          const Token(type: TokenType.tagName, value: 'h1'),
          const Token(type: TokenType.closingTag, value: '>'),
          const Token(type: TokenType.eof, value: ''),
        ]),
      );
    });
  });
}
