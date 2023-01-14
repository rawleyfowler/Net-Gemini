use v6;
use strict;

use IO::Socket::Async::SSL;
use Net::Gemini::Response;

# Attempts to serve a file based on the request.
sub default-handler(Str $domain, Str $request --> Net::Gemini::Response) {
    say "Got request : { $request.chomp }";
    my $requested-resource = ($request ~~ /^"gemini://$domain/"$<target-resource>=.*"\r\n"$/)<target-resource>.Str // "";
    my $response = Net::Gemini::Response::make-resource-response($requested-resource);
    say "Sending response : { $response.status-code, $response.meta }";
    $response;
}

class Net::Gemini::Server is export {
    has Str $.domain is required;
    has Str $.cert-file is required where *.IO.e;
    has Str $.cert-key-file is required where *.IO.e;
    has Int $.port = 1965;

    # Will attempt to serve .gmi files for given paths
    multi method listen() {
        self.listen({ &default-handler($!domain, $^a) });
    }

    # Will do and return whatever your callback does
    # handler : Str -> Net::Gemini::Response
    multi method listen(&handler) {
        react {
            my %ssl-config = certificate-file => $!cert-file, private-key-file => $!cert-key-file;
            whenever IO::Socket::Async::SSL.listen('localhost', $!port, |%ssl-config) -> $connection {
                whenever $connection -> $data {
                    unless $data.starts-with("gemini://$!domain") {
                        $connection.print: Net::Gemini::Response::make-generic-response(59);
                        return;
                    }

                    $connection.print: &handler($data);

                    CATCH {
                        default {
                            .say;
                            $connection.print: Net::Gemini::Response::make-generic-response(50);
                        }
                    }

                    LEAVE {
                        $connection.close;
                    }
                }
            }
        }
    }
}

# vim: expandtab shiftwidth=4
