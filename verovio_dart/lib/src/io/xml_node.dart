/// A mutable XML tree used by the input filters, mirroring the `pugixml`
/// document model that the C++ Verovio relies on.
///
/// The Dart `package:xml` tree is immutable; the readers need to remove,
/// rename and append attributes while reading (upgrades of older MEI
/// versions, @xml:id consumption…). Nodes are parsed with `package:xml` and
/// converted into this lightweight tree.
library;

import 'package:xml/xml.dart';

/// Node kinds (mirrors pugi::xml_node_type, restricted to what is needed).
enum MeiXmlNodeType { element, text, comment }

/// Mirrors a `pugi::xml_node`: an element, a text run or a comment.
class MeiXmlNode {
  /// Creates an element node.
  MeiXmlNode.element(this.name) : type = MeiXmlNodeType.element;

  /// Creates a text (pcdata) node.
  MeiXmlNode.text(this.value) : type = MeiXmlNodeType.text, name = '';

  /// Creates a comment node.
  MeiXmlNode.comment(this.value) : type = MeiXmlNodeType.comment, name = '';

  final MeiXmlNodeType type;

  /// Element name; empty for text and comment nodes (as in pugixml).
  String name;

  /// Text or comment content; null for elements.
  String? value;

  /// Ordered attribute map (elements only). Mutations are visible to all
  /// readers of this node.
  final Map<String, String> attributes = {};

  final List<MeiXmlNode> children = [];

  MeiXmlNode? parent;

  bool get isElement => type == MeiXmlNodeType.element;
  bool get isText => type == MeiXmlNodeType.text;
  bool get isComment => type == MeiXmlNodeType.comment;

  /// True for nodes without children (mirrors `xml_node::empty()`).
  bool get isEmptyElement =>
      !isElement && (value == null || value!.isEmpty);

  // -------------------------------------------------------------------------
  // pugixml-like navigation helpers
  // -------------------------------------------------------------------------

  /// First child element/text/comment or null.
  MeiXmlNode? firstChild() => children.isEmpty ? null : children.first;

  MeiXmlNode? lastChild() => children.isEmpty ? null : children.last;

  /// The next sibling of this node within its parent (null if none).
  MeiXmlNode? nextSibling() {
    if (parent == null) return null;
    final int i = parent!.children.indexOf(this);
    if (i < 0 || i + 1 >= parent!.children.length) return null;
    return parent!.children[i + 1];
  }

  /// First child element with [name] (mirrors `xml_node::child`).
  MeiXmlNode? child(String name) {
    for (final MeiXmlNode node in children) {
      if (node.isElement && node.name == name) return node;
    }
    return null;
  }

  /// All direct child elements.
  List<MeiXmlNode> childrenElements() =>
      children.where((n) => n.isElement).toList();

  /// Alias of [childrenElements] used at call sites.
  List<MeiXmlNode> childElements() => childrenElements();

  /// Attribute value (null if missing; mirrors `attribute(...).value()`).
  String? attr(String name) => attributes[name];

  bool hasAttr(String name) => attributes.containsKey(name);

  void removeAttribute(String name) {
    attributes.remove(name);
  }

  void renameAttribute(String oldName, String newName) {
    if (!attributes.containsKey(oldName)) return;
    final String value = attributes.remove(oldName)!;
    attributes[newName] = value;
  }

  void setAttribute(String name, String value) {
    attributes[name] = value;
  }

  /// The value of the first text child (mirrors `xml_node::text()`).
  ///
  /// For text nodes, returns the node's own value (pugixml behaviour).
  String? textValue() {
    if (isText) return value;
    for (final MeiXmlNode node in children) {
      if (node.isText) return node.value;
    }
    return null;
  }

  /// Set / replace the first text child (mirrors `text().set(...)`).
  void setTextValue(String text) {
    if (isText) {
      value = text;
      return;
    }
    for (int i = 0; i < children.length; ++i) {
      if (children[i].isText) {
        children[i].value = text;
        return;
      }
    }
    appendChild(MeiXmlNode.text(text));
  }

  /// Append a child and set its parent link.
  void appendChild(MeiXmlNode node) {
    node.parent = this;
    children.add(node);
  }

  /// Remove a direct child.
  void removeChild(MeiXmlNode node) {
    children.remove(node);
  }

  /// Deep copy of the subtree (mirrors `append_copy`).
  MeiXmlNode copy() {
    final MeiXmlNode clone = isElement
        ? MeiXmlNode.element(name)
        : (isComment ? MeiXmlNode.comment(value ?? '') : MeiXmlNode.text(value ?? ''));
    clone.attributes.addAll(attributes);
    for (final MeiXmlNode childNode in children) {
      clone.appendChild(childNode.copy());
    }
    return clone;
  }

  /// Serialize the subtree to an XML string (used by GenericLayerElement /
  /// Svg content).
  String serialize({bool includeDeclaration = false}) {
    final StringBuffer out = StringBuffer();
    _write(out);
    return out.toString();
  }

  void _write(StringBuffer out) {
    switch (type) {
      case MeiXmlNodeType.text:
        out.write(_escapeText(value ?? ''));
        break;
      case MeiXmlNodeType.comment:
        out.write('<!--${value ?? ''}-->');
        break;
      case MeiXmlNodeType.element:
        out.write('<$name');
        attributes.forEach((k, v) {
          out.write(' $k="${_escapeAttr(v)}"');
        });
        if (children.isEmpty) {
          out.write('/>');
          return;
        }
        out.write('>');
        for (final MeiXmlNode childNode in children) {
          childNode._write(out);
        }
        out.write('</$name>');
        break;
    }
  }

  static String _escapeText(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _escapeAttr(String s) => _escapeText(s)
      .replaceAll('"', '&quot;');
}

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

/// Parse an XML string into a [MeiXmlNode] tree keeping comments
/// (mirrors `doc.load_string(mei.c_str(), parse_comments | parse_default)`).
///
/// Returns the first child of the document (or null when parsing failed).
MeiXmlNode? parseMeiXml(String data) {
  try {
    final XmlDocument doc = XmlDocument.parse(data);
    return _convertAll(doc.children);
  } on XmlException {
    return null;
  }
}

/// Convert the top level document children; returns the first meaningful
/// node wrapped as root, mirroring `doc.first_child()` usage where the
/// callers expect one root element.
MeiXmlNode? _convertAll(List<XmlNode> nodes) {
  final MeiXmlNode root = MeiXmlNode.element('#document');
  _convertInto(nodes, root);
  return root;
}

void _convertInto(List<XmlNode> nodes, MeiXmlNode parent) {
  for (final XmlNode node in nodes) {
    if (node is XmlElement) {
      final MeiXmlNode element = MeiXmlNode.element(node.name.qualified);
      for (final XmlAttribute attr in node.attributes) {
        element.attributes[attr.name.qualified] = attr.value;
      }
      parent.appendChild(element);
      _convertInto(node.children, element);
    } else if (node is XmlText) {
      final String value = node.value;
      // Mirror the pugixml default behaviour: whitespace-only pcdata nodes
      // are not stored.
      if (value.isNotEmpty && value.trim().isNotEmpty) {
        parent.appendChild(MeiXmlNode.text(value));
      }
    } else if (node is XmlComment) {
      parent.appendChild(MeiXmlNode.comment(node.value));
    }
    // Processing instructions / declarations are skipped.
  }
}
