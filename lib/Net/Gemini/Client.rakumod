use v6;
use strict;

use Net::Gemini::Response;
use IO::Socket::Async::SSL;

unit class Net::Gemini::Client;

our sub request($target, $port = 1965) {
    say $target;
    say ($target ~~ /^ 'gemini://' <( .* )> '/'? .* \r\n $/);
    my $host = ($target ~~ /^ 'gemini://'$<host>=[\w] '/' .* $/)<host> || die "Invalid target specified: $target";
    my $conn = await IO::Socket::Async::SSL.connect($host, $port);

    $conn.print: $target ~ qq{\x[0d]\x[0a]};
    return do react {
        whenever $conn {
            LEAVE { $conn.close }
            return $_;
        }
    }
}

submethod CALL-ME($target, $port = 1965) {
    &request($target, $port);
}

# vim: expandtab shiftwidth=4
