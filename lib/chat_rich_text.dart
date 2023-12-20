import 'package:flutter/material.dart';

class ChatRichText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final InlineSpan? prefixSpan;

  /// isReceived ? TextAlign.left : TextAlign.right
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int? maxLines;
  final double textScaleFactor;

  /// all user info
  /// key:userid
  /// value:username
  final Map<String, String> allAtMap;
  final List<MatchPattern> patterns;
  final ChatTextType textType;

  const ChatRichText({
    Key? key,
    required this.text,
    this.allAtMap = const <String, String>{},
    this.prefixSpan,
    this.patterns = const <MatchPattern>[],
    this.textAlign = TextAlign.left,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.textStyle,
    this.maxLines,
    this.textType = ChatTextType.match,
  }) : super(key: key);

  @override
  State<ChatRichText> createState() => _ChatRichTextState();
}

class _ChatRichTextState extends State<ChatRichText> {
  final List<InlineSpan> children = <InlineSpan>[];
  final _textStyle = const TextStyle(
    fontSize: 14,
    color: Color(0xFF333333),
  );
  @override
  void initState() {
    initUI();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      textScaleFactor: widget.textScaleFactor,
      text: TextSpan(children: children),
    );
  }

  void initUI() {
    if (widget.prefixSpan != null) children.add(widget.prefixSpan!);

    if (widget.textType == ChatTextType.normal) {
      _normalModel(children);
    } else {
      _matchModel(children);
    }
  }

  _normalModel(List<InlineSpan> children) {
    var style = widget.textStyle ?? _textStyle;
    children.add(TextSpan(text: widget.text, style: style));
  }

  _matchModel(List<InlineSpan> children) {
    var style = widget.textStyle ?? _textStyle;

    final _mapping = Map<String, MatchPattern>();

    for (var e in widget.patterns) {
      if (e.type == PatternType.at) {
        _mapping[regexAt] = e;
      } else if (e.type == PatternType.email) {
        _mapping[regexEmail] = e;
      } else if (e.type == PatternType.mobile) {
        _mapping[regexMobile] = e;
      } else if (e.type == PatternType.tel) {
        _mapping[regexTel] = e;
      } else if (e.type == PatternType.url) {
        _mapping[regexUrl] = e;
      } else {
        _mapping[e.pattern!] = e;
      }
    }
  }
}

enum ChatTextType { match, normal } //富文本 正常文本

class MatchPattern {
  PatternType type;

  String? pattern;

  TextStyle? style;

  Function(String link, PatternType? type)? onTap;

  MatchPattern({required this.type, this.pattern, this.style, this.onTap});
}

enum PatternType { at, email, mobile, tel, url, emoji, custom }

/// 空格@uid空格 @xxx-
/// r"(\s@\S+\-)"
const regexAt = r"(@[\w\d\-\u4e00-\u9fa5]+#\d+#)";

/// Email Regex - A predefined type for handling email matching
const regexEmail = r"\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b";

/// URL Regex - A predefined type for handling URL matching
const regexUrl =
    r"[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:._\+-~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:_\+.~#?&\/\/=]*)";

// Regex of exact mobile.
const String regexMobile =
    '^(\\+?86)?((13[0-9])|(14[57])|(15[0-35-9])|(16[2567])|(17[01235-8])|(18[0-9])|(19[1589]))\\d{8}\$';

/// Regex of telephone number.
const String regexTel = '^0\\d{2,3}[-]?\\d{7,8}';
