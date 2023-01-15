use v6;
use strict;

use Net::Gemini::Response;
use IO::Socket::Async::SSL;

unit class Net::Gemini::Client;

has Supply $.supply is required;

method Supply {
    $.supply;
}

submethod request($target, $port = 1965) {
    die "Invalid target specified: $target" unless $target ~~ /^ 'gemini://' (<-[/]>+) '/'?/;

    my $host = $0.Str;
    my $conn = await IO::Socket::Async::SSL.connect($host, $port, :insecure); # Insecure because it is normal to self sign with Gemini.
    $conn.print: $target ~ qq{\x[0d]\x[0a]};
    return Net::Gemini::Client.new(supply => $conn.Supply);
}

submethod CALL-ME($target, $port = 1965) {
    Net::Gemini::Client.request($target, $port);
}

# vim: expandtab shiftwidth=4
