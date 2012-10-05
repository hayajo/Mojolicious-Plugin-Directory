use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use File::Basename;
use Encode ();

my $dir = dirname(__FILE__);
plugin 'Directory', root => $dir;

use Test::More tests => 3;
use Test::Mojo;

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200);

subtest 'entries' => sub {
    my $dh = DirHandle->new($dir);
    while ( defined( my $ent = $dh->read ) ) {
        next if $ent eq '.' or $ent eq '..';
        $ent = Encode::decode_utf8($ent);
        $t->content_like(qr/$ent/);
    }
}
