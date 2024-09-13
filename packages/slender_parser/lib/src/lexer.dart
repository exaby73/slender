import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:slender_parser/src/errors.dart';
import 'package:slender_parser/src/tokens.dart';

final class Lexer {
  late final String content;
  int position = 0;

  Lexer({required String content}) {
    this.content = content.trim();
  }

  @visibleForTesting
  void debug() {
    for (final token in tokens) {
      // ignore: avoid_print
      print(token);
    }
    // ignore: avoid_print
    print('Debug called... Exiting');
    exit(0);
  }

  Iterable<Token> get tokens => _generateTokens().where((token) {
    if (token.type != TokenType.text) return true;
    return token.value.trim().isNotEmpty;
  });

  Iterable<Token> _generateTokens() sync* {
    while (position < content.length) {
      final char = content[position];
      if (char == '<') {
        position++;
        if (peek() == '/') {
          position++;
          yield const Token(type: TokenType.openingClosingTag, value: '</');
          yield* _nextTagAndAttributes();
          continue;
        }
        yield const Token(type: TokenType.openingTag, value: '<');
        if (peek(6) == 'script') {
          position += 6;
          yield const Token(type: TokenType.scriptTagName, value: 'script');
          final char = content[position];
          if (char == ' ') {
            position++;
            yield* _nextTagAndAttributes(ignoreTagName: true);
          } else if (char == '>') {
            position++;
            yield const Token(type: TokenType.closingTag, value: '>');
          } else {
            throw UnexpectedTokenError('Expected space or > after script');
          }
          yield* _nextString(TokenType.scriptClosingTag);
          continue;
        }
        yield* _nextTagAndAttributes();
      }
      if (char == '=') {
        position++;
        yield const Token(type: TokenType.equals, value: '=');
      }
      if (char == '"') {
        position++;
        yield const Token(type: TokenType.stringDoubleStart, value: '"');
        yield* _nextString(TokenType.stringDoubleEnd);
      }
      if (char == "'") {
        position++;
        yield const Token(type: TokenType.stringSingleStart, value: "'");
        yield* _nextString(TokenType.stringSingleEnd);
      }
      if (char == '{') {
        position++;
        if (peek(2) == 'if') {
          position += 2;
          yield const Token(type: TokenType.ifStart, value: '{if');
          if (peek() != ' ') {
            throw UnexpectedTokenError('Expected space after {if');
          }
          position++;
          yield* _nextExpression();
          yield* _nextString(TokenType.ifEnd);
          continue;
        }

        if (peek(3) == 'for') {
          position += 3;
          yield const Token(type: TokenType.loopStart, value: '{for');
          if (peek() != ' ') {
            throw UnexpectedTokenError('Expected space after {for');
          }
          position++;
          yield* _nextLoopExpression();
          yield* _nextString(TokenType.loopEnd);
          continue;
        }
        yield* _nextExpression();
      }

      yield* _nextText();
    }

    yield const Token(type: TokenType.eof, value: '');
  }

  Iterable<Token> _nextText() sync* {
    final buffer = StringBuffer();
    while (position < content.length) {
      final char = content[position];
      if (char == '<' || char == '{') {
        if (buffer.isNotEmpty) {
          yield Token(type: TokenType.text, value: buffer.toString());
        }
        break;
      }
      buffer.write(char);
      position++;
    }
  }

  Iterable<Token> _nextLoopExpression() sync* {
    final expressionBuffer = StringBuffer();
    final stepBuffer = StringBuffer();
    final indexBuffer = StringBuffer();
    bool expressionDone = false;
    while (position < content.length) {
      var char = content[position];
      if (char == '}') {
        if (expressionBuffer.isEmpty) {
          throw UnexpectedTokenError('Expected expression after {for');
        }
        yield Token(
          type: TokenType.expression,
          value: expressionBuffer.toString(),
        );
        if (stepBuffer.isNotEmpty) {
          yield Token(type: TokenType.loopStep, value: stepBuffer.toString());
        }
        if (indexBuffer.isNotEmpty) {
          yield Token(type: TokenType.loopIndex, value: indexBuffer.toString());
        }
        position++;
        break;
      }
      if (peek(5) == 'step ') {
        position += 5;
        expressionDone = true;
        char = content[position];
        while (char != ' ' || char != '}') {
          if (int.tryParse(char) == null) {
            throw UnexpectedTokenError('Expected number after step');
          }
          stepBuffer.write(char);
          position++;
          char = content[position];
        }
      }

      if (peek() == '<') {
        position++;
        expressionDone = true;
        char = content[position];
        while (char != '>') {
          indexBuffer.write(char);
          position++;
          char = content[position];
        }
      }
      if (!expressionDone) expressionBuffer.write(char);
      position++;
    }
  }

  Iterable<Token> _nextString(TokenType endType) sync* {
    final buffer = StringBuffer();
    while (position < content.length) {
      final char = content[position];
      if (char == '\\') {
        buffer.write(char);
        position++;
        buffer.write(content[position]);
        position++;
        continue;
      }
      final endString = endType.toString();
      if (peek(endString.length) == endString) {
        yield Token(type: TokenType.text, value: buffer.toString().trim());
        yield Token(type: endType, value: endType.toString());
        position += endString.length;
        break;
      }
      buffer.write(char);
      position++;
    }
  }

  Iterable<Token> _nextTagAndAttributes({bool ignoreTagName = false}) sync* {
    final buffer = StringBuffer();
    bool tagNameDone = ignoreTagName;
    while (position < content.length) {
      final tagEnded = peek() == '>' || peek(2) == '/>';
      if (tagEnded) {
        if (buffer.isEmpty) {
          throw UnexpectedTokenError('Expected tag name');
        }
        if (!tagNameDone) {
          yield Token(type: TokenType.tagName, value: buffer.toString());
        }
        if (peek(2) == '/>') {
          yield const Token(type: TokenType.closingTag, value: '/>');
          position += 2;
        } else {
          yield const Token(type: TokenType.closingTag, value: '>');
          position++;
        }
        break;
      }
      final char = content[position];
      if (tagNameDone) {
        yield* _nextAttributes();
        return;
      }

      if (char == ' ') {
        yield Token(type: TokenType.tagName, value: buffer.toString());
        position++;
        tagNameDone = true;
        continue;
      }
      buffer.write(char);
      position++;
    }
  }

  Iterable<Token> _nextAttributes() sync* {
    final buffer = StringBuffer();
    while (position < content.length) {
      final tagEnded = peek() == '>' || peek(2) == '/>';
      if (tagEnded) {
        if (buffer.isNotEmpty) {
          yield Token(type: TokenType.attribute, value: buffer.toString());
        }
        if (peek(2) == '/>') {
          yield const Token(type: TokenType.closingTag, value: '/>');
          position += 2;
        } else {
          yield const Token(type: TokenType.closingTag, value: '>');
          position++;
        }
        break;
      }
      final char = content[position];
      if (char == '=') {
        yield Token(type: TokenType.attribute, value: buffer.toString());
        yield const Token(type: TokenType.equals, value: '=');
        position++;
        if (peek() == '"') {
          position++;
          yield const Token(type: TokenType.stringDoubleStart, value: '"');
          final string = _nextString(TokenType.stringDoubleEnd).toList();
          string[0] = Token(
            type: TokenType.attributeValue,
            value: string.first.value,
          );
          yield* string;
        } else if (peek() == "'") {
          position++;
          yield const Token(type: TokenType.stringSingleStart, value: "'");
          final string = _nextString(TokenType.stringSingleEnd).toList();
          string[0] = Token(
            type: TokenType.attributeValue,
            value: string.first.value,
          );
          yield* string;
        } else if (peek() == '{') {
          position++;
          yield* _nextExpression();
        } else {
          throw UnexpectedTokenError('Expected string or expression');
        }
        buffer.clear();
        continue;
      }
      if (char == ' ') {
        yield Token(type: TokenType.attribute, value: buffer.toString());
        position++;
        buffer.clear();
        continue;
      }
      buffer.write(char);
      position++;
    }
  }

  Iterable<Token> _nextExpression() sync* {
    final buffer = StringBuffer();
    while (position < content.length) {
      final char = content[position];
      if (char == '}') {
        if (buffer.isEmpty) {
          throw UnexpectedTokenError('Expected expression');
        }
        yield Token(type: TokenType.expression, value: buffer.toString());
        position++;
        break;
      }
      buffer.write(char);
      position++;
    }
  }

  String peek([int n = 1]) {
    return content.substring(position, min(position + n, content.length));
  }
}
