use v6;
use strict;

use IO::Socket::Async::SSL;

unit module Net::Gemini::Server;

my constant %STATUS-CODES is export =
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

my sub make-redirect-response($location, $domain) {
    "gemini://$domain$location"
}

my sub make-non-success-response(Int $status, $domain) is export {
    die "Could not generate response for $status" without %STATUS-CODES{$status};

    my $right = do given $status {
        when 10 { "$domain is requesting input for this route." }
        when 30 <= $_ <= 31 { make-redirect-response($status, "/", $domain) }
        when 40 { "Something went wrong. Please checkback later" }
        when 41 { "Server is not available." }
        when 42 { "CGI Error occured." }
        when 43 { "Proxy error occured." }
        when 44 { "Slow down." }
        when 50 { "Something went wrong." }
        when 51 { "Content not found, go home: gemini://$domain/" }
        when 52 { "The content you're trying to reach is gone." }
        when 53 { "Proxy request refused." }
        when 59 { "Bad Request." }
        when 60 { "Certificate required for client." }
        when 61 { "Certificate not authorised." }
        when 62 { "Certificate not valid." }
    }

    "$status " ~ $right ~ "\r\n";
}


sub build-response(Str $resource, Str $domain) is export {
    my $actual-resource;
    unless $resource { # "" typically means index.
        if "index.gmi".IO.e {
            $actual-resource = "index.gmi";
        } elsif "index.gmni".IO.e {
            $actual-resource = "index.gmni";
        }
    }

    $actual-resource //= $resource;

    unless $actual-resource.IO.e {
        return make-non-success-response(51, $domain);
    }

    return "20 text/gemini; charset=utf-8\r\n{ $actual-resource.IO.slurp.chomp }";
}

our sub listen($certificate-file where $certificate-file.IO.e, $private-key-file where $private-key-file.IO.e, $domain = 'localhost', $port = 1965, &handler = { $_ }) is export {
    react {
        my %ssl-config = :$certificate-file, :$private-key-file;
        whenever IO::Socket::Async::SSL.listen('localhost', $port, |%ssl-config) -> $connection {
            whenever $connection -> $data {
                unless $data.starts-with("gemini://$domain") {
                    $connection.print: "59 text/gemini\r\n# Bad Request\r\n";
                    return;
                }

                my $request = ($data ~~ /^"gemini://$domain/"$<target-resource>=.*"\r\n"$/)<target-resource>.Str // "";
                my $response = &handler(build-response($request, $domain));
                $connection.print($response);

                CATCH {
                    default {
                        .say;
                        $connection.print: make-non-success-response(50, $domain);
                    }
                }

                LEAVE {
                    $connection.close;
                }
            }
        }
    }
}

# vim: expandtab shiftwidth=4
