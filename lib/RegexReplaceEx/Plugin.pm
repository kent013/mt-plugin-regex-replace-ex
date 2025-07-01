package RegexReplaceEx::Plugin;

use strict;
use warnings;
use utf8;

sub _fltr_regex_replace_ex {
    my ($str, $val, $ctx) = @_;

    return $str unless defined $val && $val ne '';

    # Handle different input formats
    if (!ref($val)) {
        # Single string format: /pattern/replacement/flags
        return _process_single_format($str, $val);
    }
    elsif (ref($val) eq 'ARRAY') {
        # Array format: ["pattern", "replacement"]
        return _process_array_format($str, $val);
    }

    return $str;
}

sub _process_single_format {
    my ($str, $val) = @_;

    # Parse /pattern/replacement/flags format
    return $str unless $val =~ m{^/};

    # Remove leading slash
    my $content = substr($val, 1);

    # Find the last slash (end delimiter)
    my $last_slash_pos = rindex($content, '/');
    return $str if $last_slash_pos < 0;

    # Extract flags
    my $flags = substr($content, $last_slash_pos + 1) || '';
    my $pattern_replacement = substr($content, 0, $last_slash_pos);

    # Find the middle slash separating pattern and replacement
    my ($pattern, $replacement) = _split_pattern_replacement($pattern_replacement);
    return $str unless defined $pattern;

    # Debug output
    if ($ENV{MT_DEBUG}) {
        warn "RegexReplaceEx: Parsed - Pattern='$pattern', Replacement='$replacement', Flags='$flags'";
    }

    return _apply_regex($str, $pattern, $replacement, $flags);
}

sub _process_array_format {
    my ($str, $val) = @_;

    my ($pattern_str, $replacement) = @$val;
    $pattern_str = '' unless defined $pattern_str;
    $replacement = '' unless defined $replacement;

    # Extract pattern and flags from pattern string
    if ($pattern_str =~ m{^/(.+)/([gim]*)$}) {
        my $pattern = $1;
        my $flags = $2 || '';
        return _apply_regex($str, $pattern, $replacement, $flags);
    }
    else {
        # Simple string replacement
        $str =~ s/\Q$pattern_str\E/$replacement/g;
        return $str;
    }
}

sub _split_pattern_replacement {
    my ($content) = @_;

    # Find the first unescaped slash
    my $pos = 0;
    my $len = length($content);
    my $escape_count = 0;

    while ($pos < $len) {
        my $char = substr($content, $pos, 1);

        if ($char eq '\\') {
            $escape_count++;
        }
        elsif ($char eq '/' && $escape_count % 2 == 0) {
            # Found unescaped slash
            my $pattern = substr($content, 0, $pos);
            my $replacement = substr($content, $pos + 1);
            return ($pattern, $replacement);
        }
        else {
            $escape_count = 0;
        }

        $pos++;
    }

    return;
}

sub _apply_regex {
    my ($str, $pattern, $replacement, $flags) = @_;

    # Parse flags
    my $global = ($flags =~ /g/) ? 1 : 0;
    my $case_insensitive = ($flags =~ /i/) ? 1 : 0;
    my $multiline = ($flags =~ /m/) ? 1 : 0;

    # Build regex modifiers
    my $modifiers = '';
    $modifiers .= 'i' if $case_insensitive;
    $modifiers .= 'm' if $multiline;

    # Compile regex
    my $regex_str = $modifiers ? "(?$modifiers:$pattern)" : $pattern;
    my $re = eval { qr/$regex_str/ };

    unless (defined $re) {
        warn "RegexReplaceEx: Failed to compile pattern: $pattern" if $ENV{MT_DEBUG};
        return $str;
    }

    # Process replacement string
    my $processed_replacement = _process_replacement($replacement);

    # Perform replacement
    my $result = $str;
    my $count = 0;

    if ($global) {
        $count = $result =~ s/$re/_expand_replacement($processed_replacement, $1, $2, $3, $4, $5, $6, $7, $8, $9)/ge;
    }
    else {
        $count = $result =~ s/$re/_expand_replacement($processed_replacement, $1, $2, $3, $4, $5, $6, $7, $8, $9)/e;
    }

    if ($ENV{MT_DEBUG}) {
        if ($count > 0) {
            warn "RegexReplaceEx: Replaced $count occurrence(s): '$str' -> '$result'";
        }
        else {
            warn "RegexReplaceEx: No matches found for pattern: $pattern";
        }
    }

    return $result;
}

sub _process_replacement {
    my ($replacement) = @_;

    # Handle escape sequences
    $replacement =~ s/\\\//\x{001}/g;  # Temporarily replace \/ with a placeholder
    $replacement =~ s/\\n/\n/g;
    $replacement =~ s/\\t/\t/g;
    $replacement =~ s/\\r/\r/g;

    # Handle backreferences - convert $1 to \1 for internal use
    $replacement =~ s/\$(\d)/\\$1/g;

    # Restore escaped slashes
    $replacement =~ s/\x{001}/\//g;

    return $replacement;
}

sub _expand_replacement {
    my ($template, @captures) = @_;

    # Replace backreferences with captured values
    my $result = $template;

    for (my $i = 1; $i <= 9; $i++) {
        my $capture = $captures[$i - 1];
        $capture = '' unless defined $capture;
        $result =~ s/\\$i/$capture/g;
    }

    return $result;
}

1;
