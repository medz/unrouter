import 'dart:io';

import 'package:coal/coal.dart';
import 'package:coal/utils.dart'
    show eraseLines, cursorUp, getTextTruncatedWidth;

bool _noColor = Platform.environment.containsKey('NO_COLOR');

void configureOutput({bool? noColor}) {
  if (noColor != null) {
    _noColor = noColor;
  }
}

bool _ansiStdoutEnabled() => stdout.supportsAnsiEscapes && !_noColor;
bool _ansiStderrEnabled() => stderr.supportsAnsiEscapes && !_noColor;

String heading(String text) {
  return _styleStdout(text, const [TextStyle.bold, TextStyle.cyan]);
}

String infoLabel(String text) {
  return _styleStdout(text, const [TextStyle.blue, TextStyle.bold]);
}

String successLabel(String text) {
  return _styleStdout(text, const [TextStyle.green, TextStyle.bold]);
}

String failureLabel(String text) {
  return _styleStdout(text, const [TextStyle.red, TextStyle.bold]);
}

String warningLabel(String text) {
  return _styleStdout(text, const [TextStyle.yellow, TextStyle.bold]);
}

String errorLabel(String text) {
  return _styleStderr(text, const [TextStyle.red, TextStyle.bold]);
}

String accentText(String text, TextStyle color, {bool bold = false}) {
  final styles = <TextStyle>[color];
  if (bold) {
    styles.add(TextStyle.bold);
  }
  return _styleStdout(text, styles);
}

String badge(
  String text, {
  TextStyle background = TextStyle.bgBlue,
  TextStyle foreground = TextStyle.white,
}) {
  if (!_ansiStdoutEnabled()) return '[$text]';
  return styleText(' $text ', [background, foreground, TextStyle.bold]);
}

String pathText(String text, {bool stderr = false}) {
  return stderr
      ? _styleStderr(text, const [TextStyle.cyan])
      : _styleStdout(text, const [TextStyle.cyan]);
}

String dimText(String text) {
  return _styleStdout(text, const [TextStyle.dim]);
}

String fitToTerminal(String text, {int padding = 0}) {
  final width = _terminalWidth(padding: padding);
  if (width == null) return text;
  return truncateAnsi(text, width);
}

int? _terminalWidth({int padding = 0}) {
  if (!stdout.hasTerminal) return null;
  final width = stdout.terminalColumns - padding;
  if (width <= 0) return null;
  return width;
}

void renderBlock(List<String> lines) {
  if (lines.isEmpty) return;
  for (final line in lines) {
    stdout.writeln(line);
  }
}

void rewriteBlock(List<String> lines, {required int previousLineCount}) {
  if (!stdout.supportsAnsiEscapes || previousLineCount <= 0) {
    renderBlock(lines);
    return;
  }
  stdout.write(cursorUp(previousLineCount));
  stdout.write(eraseLines(previousLineCount));
  renderBlock(lines);
}

String truncateAnsi(String text, int maxWidth, {String ellipsis = '...'}) {
  if (maxWidth <= 0 || text.isEmpty) return '';
  var effectiveEllipsis = ellipsis;
  if (ellipsis.isNotEmpty) {
    final ellipsisWidth = getTextTruncatedWidth(
      ellipsis,
      limit: double.infinity,
      ellipsis: '',
    ).width;
    if (ellipsisWidth > maxWidth) {
      final clipped = getTextTruncatedWidth(
        ellipsis,
        limit: maxWidth,
        ellipsis: '',
      );
      effectiveEllipsis = ellipsis.substring(0, clipped.index);
    }
  }
  final result = getTextTruncatedWidth(
    text,
    limit: maxWidth,
    ellipsis: effectiveEllipsis,
  );
  if (!result.truncated) return text;
  final end = result.index.clamp(0, text.length);
  return text.substring(0, end) + (result.ellipsed ? effectiveEllipsis : '');
}

String _styleStdout(String text, List<TextStyle> styles) {
  if (!_ansiStdoutEnabled()) return text;
  return styleText(text, styles);
}

String _styleStderr(String text, List<TextStyle> styles) {
  if (!_ansiStderrEnabled()) return text;
  return styleText(text, styles);
}
