# Net::Gemini
Fairly low level bindings to the gemini network protocol.

## How to use

#### Client
```raku
use Net::Gemini;

my $client = Net::Gemini::Client('gemini://gemini.website.space') # Defaults port to 1965, specify port if you want.
react {
    whenever $client {
        say $_;
    }
}
```

#### Server

##### File Server
```raku
use Net::Gemini;

my $domain = 'www.bob.com';
my $port = 1965; # This is defaulted if not provided
my $cert-file = 'cert.pem'; # TLS is required for Gemini, so you need a cert file and priv-key
my $cert-key-file = 'priv-key.pem';
Net::Gemini::Server.new(:$domain, :$port, :$cert-file, :$cert-key-file).listen;
# This will serve .gmi and .gmni files from $*CWD
# If you include index.gmi in the directory you'll see it become available on the root route.
```

##### Custom Handler Server
```raku
use Net::Gemini;

# Same as file server
my $domain = 'www.bob.com';
my $port = 1965; # This is defaulted if not provided
my $cert-file = 'cert.pem'; # TLS is required for Gemini, so you need a cert file and priv-key
my $cert-key-file = 'priv-key.pem';

# Custom handler for requests.
sub my-handler(Str $request --> Net::Gemini::Response) {
    # There are some generic/pre-built functions for generating responses in
    # Response.rakumod, these help a lot!
    if $request eq ('gemini://www.bob.com/') {
        Net::Gemini::Response::make-generic-redirect-response(31, 'gemini://www.bob.com/redirect');
    } else {
        Net::Gemini::Response::make-resource-response('awesome-page.gmi'); # In this case let's just always serve
    }
}

# Alternatively, if you understand the Gemini protocol you can build response using the Net::Gemini::Response class.

Net::Gemini::Server.new(:$domain, :$port, :$cert-file, :$cert-key-file).listen;
```

## License
This project is available under the Artistic-2.0 license, the same as Raku.
