use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use File::Basename;
use File::Spec;
use Encode ();

my $dir = dirname(__FILE__);
plugin 'Directory', root => $dir, handler => sub {
    my ($c, $path) = @_;
    $c->render( data => $path, format => 'txt' ) if (-f $path);
};

use Test::More tests => 3;
use Test::Mojo;

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200);

use File::Basename;
subtest 'entries' => sub {
    my $dh = DirHandle->new($dir);
    while ( defined( my $ent = $dh->read ) ) {
        $ent = Encode::decode_utf8($ent);
        next if $ent eq '.' or $ent eq '..';
        given ( my $path = File::Spec->catdir( $dir, $ent ) ) {
            when (-f) {
                $t->get_ok("/$ent")->status_is(200)->content_is( Encode::encode_utf8($path) );
            }
            when (-d) {
                $t->get_ok("/$ent")->status_is(200)->content_like( qr/Parent Directory/ );
            }
            default { ok 0 }
        }
    }
}
