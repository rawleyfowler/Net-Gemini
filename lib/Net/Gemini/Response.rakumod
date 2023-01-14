use v6;

unit class Net::Gemini::Response;

our %STATUS-CODES is export =
10, 'Input',
20, 'Success',
30, 'Redirect - Temporary',
31, 'Redirect - Permanent',
40, 'Temporary Failure',
41, 'Server Unavailable',
42, 'CGI Error',
43, 'Proxy Error',
44, 'Slow Down',
50, 'Permanent Failure',
51, 'Not Found',
52, 'Gone',
53, 'Proxy Request Refused',
59, 'Bad Request',
60, 'Client Certificate Required',
61, 'Certificate Not Authorised',
62, 'Certificate Not Valid';

our grammar Parser is export {
    has Bool $.valid;
    token TOP {
        <status>\s<meta><crlf>
        $<body>=.*
    }
    token status {
        | [ 10 | 20 | 30 | 31 | 40 | 41 | 42 | 43 | 44 | 50 | 51 | 52 | 53 | 59 | 60 | 61 | 62 ] <.accept>
        | <-[\/]>+ <.error>
    }
    token meta { .* }
    token crlf { \x[0d]\x[0a] }

    method accept {
        $!valid = True;
        self;
    }

    method error {
        $!valid = False;
        self;
    }
}

our sub make-generic-redirect-response(Int $status-code where 30 <= $status-code <= 31,
Str $redirect-to
--> Net::Gemini::Response) is export {
    my $meta = $redirect-to.starts-with('gemini://') ?? $redirect-to !! 'gemini://' ~ $redirect-to;
    Net::Gemini::Response.new(:$meta, :$status-code);
}

our sub make-generic-response(Int $status-code --> Net::Gemini::Response) is export {
    die "Could not generate response for invalid status: $status-code" without %STATUS-CODES{$status-code};
    die "If you want to make a redirect, please use Net::Gemini::Response::make-generic-redirect-response" if 30 <= $status-code <= 31;

    my $meta = do given $status-code {
        when 10 { "This route requires input." }
        when 20 { "text/gemini" }
        when 40 { "Something went wrong. Please checkback later." }
        when 41 { "Server is not available." }
        when 42 { "CGI Error occured." }
        when 43 { "Proxy error occured." }
        when 44 { "Slow down." }
        when 50 { "Something went wrong." }
        when 51 { "Content not found" }
        when 52 { "The content you're trying to reach is gone." }
        when 53 { "Proxy request refused." }
        when 59 { "Bad Request." }
        when 60 { "Certificate required for client." }
        when 61 { "Certificate not authorised." }
        when 62 { "Certificate not valid." }
    }

    Net::Gemini::Response.new(:$meta, :$status-code)
}

our sub make-resource-response(Str $resource, Str $encoding = 'text/gemini; charset=utf-8' --> Net::Gemini::Response) is export {
    my $actual-resource;
    unless $resource { # "" typically means index.
        if "index.gmi".IO.e {
            $actual-resource = "index.gmi";
        } elsif "index.gmni".IO.e {
            $actual-resource = "index.gmni";
        }
    }

    unless $resource.ends-with: '.gmi' {
        if "$resource.gmi".IO.e {
            $actual-resource = "$resource.gmi";
        } elsif "$resource.gmni".IO.e {
            $actual-resource = "$resource.gmni";
        }
    }

    $actual-resource //= $resource;

    unless $actual-resource.IO.e {
        return make-generic-response(51);
    }

    my $meta = $encoding;
    my $status-code = 20;
    my $body = $actual-resource.IO.slurp.chomp;
    Net::Gemini::Response.new(:$meta, :$status-code, :$body);
}

has Int $.status-code is required;
has Str $.meta = "";
has Str $.body = "";

method TWEAK {
    die "Invalid status code: $!status-code" unless $!status-code ∈ %STATUS-CODES.keys.map({ .Int });
}

submethod encode(Str $raw --> Net::Gemini::Response) {
    my $match = Net::Gemini::Response::Parser.parse($raw);
    say $match;
    $match.Str;
}

# Decode response for delivery
method decode(--> Str) {
    qq/$.status-code $.meta\r\n$.body\r\n/
}

method Str {
    self.decode;
}

method gist {
    self.decode;
}

method raku {
    self.decode;
}

# vim: expandtab shiftwidth=4
