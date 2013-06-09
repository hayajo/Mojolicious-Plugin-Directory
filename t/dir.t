use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use File::Basename;
use Encode ();

my $dir = dirname(__FILE__);
plugin 'Directory', root => $dir, json => 1;

use Test::More tests => 2;
use Test::Mojo;

my $t = Test::Mojo->new();

subtest 'entries' => sub {
    $t->get_ok('/')->status_is(200);

    my $dh = DirHandle->new($dir);
    while ( defined( my $ent = $dh->read ) ) {
        next if $ent eq '.' or $ent eq '..';
        $ent = Encode::decode_utf8($ent);
        $t->content_like(qr/$ent/);
    }
};

subtest 'json' => sub {
    $t->get_ok('/?format=json')
      ->status_is(200)
      ->content_type_is('application/json');
};
