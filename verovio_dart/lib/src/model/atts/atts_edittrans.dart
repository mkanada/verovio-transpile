// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_edittrans.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.AgentIdent` (mirrors `vrv::AttAgentIdent`).
mixin AttAgentIdent {
  /// `agent` — std::string.
  String? agent;
  bool get hasAgent => agent != null;

  /// Mirrors `AttAgentIdent::ReadAgentIdent`.
  bool readAgentIdent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final agentRaw = element.get('agent');
    if (agentRaw != null) {
      agent = identityStr(agentRaw);
      if (removeAttr) element.remove('agent');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAgentIdent::WriteAgentIdent`.
  void writeAgentIdent(XmlBuilder element) {
    if (hasAgent) {
      element.attribute('agent', identityStr(agent!));
    }
  }

  /// Copies the `AttAgentIdent` members from [other].
  void copyAttAgentIdent(covariant AttAgentIdent other) {
    agent = other.agent;
  }
}

/// MEI attribute class for `att.ReasonIdent` (mirrors `vrv::AttReasonIdent`).
mixin AttReasonIdent {
  /// `reason` — std::string.
  String? reason;
  bool get hasReason => reason != null;

  /// Mirrors `AttReasonIdent::ReadReasonIdent`.
  bool readReasonIdent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final reasonRaw = element.get('reason');
    if (reasonRaw != null) {
      reason = identityStr(reasonRaw);
      if (removeAttr) element.remove('reason');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttReasonIdent::WriteReasonIdent`.
  void writeReasonIdent(XmlBuilder element) {
    if (hasReason) {
      element.attribute('reason', identityStr(reason!));
    }
  }

  /// Copies the `AttReasonIdent` members from [other].
  void copyAttReasonIdent(covariant AttReasonIdent other) {
    reason = other.reason;
  }
}
