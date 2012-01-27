use strict;
use warnings;

use Test::Spec;
use IO::Socket::INET;
use LWP::UserAgent;

use_ok 'Nginx::Runner';


describe 'Nginx::Runner' => sub {
    it "should proxy http request" => sub {
        my $nginx = new_ok 'Nginx::Runner';

        my $port_dst = &fork_simple_http_client;

        my $port_src = &gen_port;

        $nginx->proxy("127.0.0.1:$port_src" => "127.0.0.1:$port_dst")->run;

        warn "http://127.0.0.1:$port_src";
        my $response = LWP::UserAgent->new->get("http://127.0.0.1:$port_src");

        ok $response->is_success, 'request is success';
        is $response->decoded_content, "ok\r\n", 'content is right';

        $nginx->stop;
    };

};

runtests unless caller;

sub gen_port {
    my $socket = IO::Socket::INET->new(LocalAddr => '127.0.0.1');
    $socket->sockport;
}

sub fork_simple_http_client {
    my $port_dst = &gen_port;

    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $port_dst,
        Listen    => 1,
    );

    return $port_dst if (fork);

    simple_http_client($socket->accept);
    exit 0;
}

sub simple_http_client {
    my $client = shift;

    while ($client->recv(my $data, 1024)) {};

    $client->send(<<"HTTP");
HTTP/1.0 200 OK\r
Date: Fri, 20 Jan 2012 13:44:14 GMT\r
Content-Type: text/plain\r
Content-Length: 4\r
\r
ok\r
HTTP

    $client->close;
}
