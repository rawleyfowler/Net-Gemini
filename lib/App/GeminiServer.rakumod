use v6;
use strict;

use IO::Socket::Async::SSL;

unit module App::GeminiServer;

my constant %status-codes = 10, 'Input',
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

our sub listen($certificate-file, $private-key-file, $domain, $port = 1965) is export {
    react {
        my %ssl-config = :$certificate-file, :$private-key-file;
        say "Gemini Server started: gemini://$domain:$port";
        whenever IO::Socket::Async::SSL.listen('localhost', $port, |%ssl-config) -> $connection {
            whenever $connection -> $data {
                say $data;
                if not ($data.starts-with("gemini://$domain")) {
                    $connection.print: "59 text/gemini\r\n# Bad Request";
                } else {
                    $connection.print: "20 text/gemini\r\n# Hello World\r\nWelcome to my Gemini Capsule!";
                }
            }
        }
    }
}

# vim: expandtab shiftwidth=4
