import 'package:flutter/material.dart';

import 'code_highlighter_engine.dart';
import 'code_highlighter_theme.dart';

export 'code_highlighter_engine.dart';
export 'code_highlighter_theme.dart';

class StoryScriptCodeHighlighterController extends TextEditingController {
  StoryScriptCodeHighlighterController({
    super.text,
    StoryScriptCodeHighlighterTheme? theme,
    StoryScriptSyntaxEngine? engine,
  }) : _theme = theme ?? StoryScriptCodeHighlighterTheme.defaults,
       _engine = engine ?? const StoryScriptSyntaxEngine();

  StoryScriptCodeHighlighterTheme _theme;
  StoryScriptSyntaxEngine _engine;

  StoryScriptCodeHighlighterTheme get theme => _theme;
  set theme(StoryScriptCodeHighlighterTheme value) {
    _theme = value;
    notifyListeners();
  }

  StoryScriptSyntaxEngine get engine => _engine;
  set engine(StoryScriptSyntaxEngine value) {
    _engine = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = _theme.baseStyle.merge(style);
    final source = text;

    if (source.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final tokens = _engine.tokenize(source);
    final composing = value.composing;

    if (!withComposing || !value.isComposingRangeValid) {
      return TextSpan(
        style: baseStyle,
        children: _buildChildren(
          source: source,
          tokens: tokens,
          start: 0,
          end: source.length,
          baseStyle: baseStyle,
        ),
      );
    }

    final children = <InlineSpan>[];

    if (composing.start > 0) {
      children.addAll(
        _buildChildren(
          source: source,
          tokens: tokens,
          start: 0,
          end: composing.start,
          baseStyle: baseStyle,
        ),
      );
    }

    children.addAll(
      _buildChildren(
        source: source,
        tokens: tokens,
        start: composing.start,
        end: composing.end,
        baseStyle: baseStyle,
        overlayStyle: const TextStyle(decoration: TextDecoration.underline),
      ),
    );

    if (composing.end < source.length) {
      children.addAll(
        _buildChildren(
          source: source,
          tokens: tokens,
          start: composing.end,
          end: source.length,
          baseStyle: baseStyle,
        ),
      );
    }

    return TextSpan(style: baseStyle, children: children);
  }

  List<InlineSpan> _buildChildren({
    required String source,
    required List<StoryScriptHighlightToken> tokens,
    required int start,
    required int end,
    required TextStyle baseStyle,
    TextStyle? overlayStyle,
  }) {
    if (start >= end) {
      return const [];
    }

    final spans = <InlineSpan>[];
    var cursor = start;

    for (final token in tokens) {
      if (token.end <= start) {
        continue;
      }

      if (token.start >= end) {
        break;
      }

      final tokenStart = token.start < start ? start : token.start;
      final tokenEnd = token.end > end ? end : token.end;

      if (tokenStart > cursor) {
        spans.add(
          TextSpan(
            text: source.substring(cursor, tokenStart),
            style: baseStyle,
          ),
        );
      }

      final tokenStyle = _theme
          .resolve(token.type, baseStyle)
          .merge(overlayStyle);
      spans.add(
        TextSpan(
          text: source.substring(tokenStart, tokenEnd),
          style: tokenStyle,
        ),
      );
      cursor = tokenEnd;
    }

    if (cursor < end) {
      spans.add(
        TextSpan(text: source.substring(cursor, end), style: baseStyle),
      );
    }

    return spans;
  }
}
