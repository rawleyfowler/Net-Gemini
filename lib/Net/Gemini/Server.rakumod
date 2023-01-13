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

my sub NOT-FOUND($domain) { "51 text/gemini\r\n# Not Found\r\n=> gemini://$domain/ Go Home\r\n" };

sub response-builder($resource, $domain) {
    unless $resource { # "" Means index
        if "index.gmi".IO.e {
            $resource = "index.gmi";
        } elsif "index.gmni".IO.e {
            $resource = "index.gmni";
        } else {
            return NOT-FOUND($domain);
        }
    }

    unless $resource.IO.e {
        return NOT-FOUND($domain);
    }

    return "20 text/gemini\r\n{ $resource.IO.slurp }\r\n";
}

our sub listen($certificate-file where $certificate-file.IO.e, $private-key-file where $private-key-file.IO.e, $domain = 'localhost', $port = 1965) is export {
    react {
        my %ssl-config = :$certificate-file, :$private-key-file;
        whenever IO::Socket::Async::SSL.listen('localhost', $port, |%ssl-config) -> $connection {
            whenever $connection -> $data {
                END {
                    $connection.close;
                }

                unless $data.starts-with("gemini://$domain") {
                    $connection.print: "59 text/gemini\r\n# Bad Request\r\n";
                }

                my $response = response-builder(($data ~~ /^"gemini://$domain/" $<target-resource>=.*/)<target-resource> || "", $domain);
                $connection.print: $response;
            }
        }
    }
}

# vim: expandtab shiftwidth=4
