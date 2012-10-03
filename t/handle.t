use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use File::Basename;
use File::Spec;

my $dir = dirname(__FILE__);
plugin 'Directory', root => $dir, handler => sub {
    my ($c, $path) = @_;
    $c->render_data( $path, format => 'txt' );
};

use Test::More tests => 3;
use Test::Mojo;

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200);

use File::Basename;
subtest 'entries' => sub {
    my $dh = DirHandle->new($dir);
    while ( defined( my $ent = $dh->read ) ) {
        next if -d $ent or $ent eq '.' or $ent eq '..';
        $t->get_ok("/$ent")->status_is(200)->content_is( File::Spec->catfile( $dir, $ent ) );
    }
}
