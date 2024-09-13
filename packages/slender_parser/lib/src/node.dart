sealed class Node {
  const Node();
}

final class FragmentNode extends Node {
  final String name;
  final Map<String, String> attributes;
  final List<Node> children;

  FragmentNode({
    required this.name,
    required this.attributes,
    required this.children,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('<$name');
    for (final entry in attributes.entries) {
      buffer.write(' ${entry.key}="${entry.value}"');
    }
    buffer.write('>');
    for (final child in children) {
      buffer.write(child);
    }
    buffer.write('</$name>');
    return buffer.toString();
  }
}

final class TextNode extends Node {
  final String text;

  const TextNode({required this.text});

  @override
  String toString() => text;
}

final class ExpressionNode extends Node {
  final String expression;

  ExpressionNode({required this.expression});
}

final class BranchNode extends Node {
  final ExpressionNode condition;
  final List<Node> children;

  BranchNode({required this.condition, required this.children});

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('{if ${condition.expression}}');
    for (final child in children) {
      buffer.write(child);
    }
    buffer.write('{endif}');
    return buffer.toString();
  }
}

final class LoopNode extends Node {
  final ExpressionNode left;
  final ExpressionNode right;
  final ExpressionNode? step;
  final ExpressionNode? index;
  final List<Node> children;

  LoopNode({
    required this.left,
    required this.right,
    this.step,
    this.index,
    required this.children,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('{for ${left.expression} in ${right.expression}');
    if (step != null) {
      buffer.write(' step ${step!.expression}');
    }
    if (index != null) {
      buffer.write(' (${index!.expression})');
    }
    for (final child in children) {
      buffer.write(child);
    }
    buffer.write('{endfor}');
    return buffer.toString();
  }
}
