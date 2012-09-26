package Mojolicious::Plugin::Directory;
use strict;
use warnings;
our $VERSION = '0.01';

use Cwd ();
use Encode ();
use DirHandle;
use Mojo::Base qw{ Mojolicious::Plugin };

# Stolen from Plack::App::Direcotry
my $dir_file = "";
my $dir_page = <<'PAGE';
<html><head>
  <title>Index of <%= $cur_url %></title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
<h1>Index of <%= $cur_url %></h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
  % for my $file (@$files) {
  <tr><td class='name'><a href='<%= $file->{url} %>'><%== $file->{name} %></a></td><td class='size'><%= $file->{size} %></td><td class='type'><%= $file->{type} %></td><td class='mtime'><%= $file->{mtime} %></td></tr>
  % }
</table>
<hr />
</body></html>
PAGE

my $types   = Mojolicious::Types->new;

sub register {
    my $self = shift;
    my ( $app, $args ) = @_;

    my $root = Mojo::Home->new( $args->{root} || Cwd::getcwd );
    $app->hook(
        before_dispatch => sub {
            my $c = shift;
            return render_file( $c, $root )
                if ( -f $root->to_string() );
            given ( my $path = $root->rel_dir( Mojo::Util::url_unescape($c->req->url) ) ) {
                when (-f) { render_file( $c, $path ) }
                when (-d) { render_indexes( $c, $path ) }
                default   {}
            }
        },
    );
    return $app;
}

sub render_file {
    my $c    = shift;
    my $file = shift;
    my $data = Mojo::Util::slurp($file);
    $c->render_data( $data, format => get_ext($file) || 'txt' );
}

sub render_indexes {
    my $c   = shift;
    my $dir = shift;

    my @files =
        ( $c->req->url eq '/' )
        ? ()
        : ( { url => '../', name => 'Parent Directory', size => '', type => '', mtime => '' } );
    my $dh = DirHandle->new($dir);
    my @children;
    while ( defined( my $ent = $dh->read ) ) {
        next if $ent eq '.' or $ent eq '..';
        push @children, Encode::decode_utf8($ent);
    }

    my $cur_url = Encode::decode_utf8( Mojo::Util::url_unescape( $c->req->url ) );
    for my $basename ( sort { $a cmp $b } @children ) {
        my $file = "$dir/$basename";
        my $url  = Mojo::Path->new($cur_url)->trailing_slash(0);
        push @{ $url->parts }, $basename;

        my $is_dir = -d $file;
        my @stat   = stat _;
        if ($is_dir) {
            $basename .= '/';
            $url->trailing_slash(1);
        }

        my $mime_type =
            $is_dir
            ? 'directory'
            : ( $types->type( get_ext($file) || 'txt' ) || 'text/plain' );
        my $mtime = Mojo::Date->new( $stat[9] )->to_string();

        push @files, {
            url   => $url,
            name  => $basename,
            size  => $stat[7] || 0,
            type  => $mime_type,
            mtime => $mtime,
        };
    }

    $c->render( inline => $dir_page, files => \@files, cur_url => $cur_url );
}

sub get_ext {
    $_[0] =~ /\.([0-9a-zA-Z]+)$/ || return;
    return lc $1;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Directory - Serve static files from document root with directory index

=head1 SYNOPSIS

  use Mojolicious::Plugin::Directory;
  app->plugin( 'Directory', root => "/path/to/htdocs" )->start;

  or

  $ perl -Mojo -E 'a->plugin("Directory", root => "/path/to/htdocs")->start' daemon

=head1 DESCRIPTION

Mojolicious::Plugin::Directory is a static file server directory index a la Apache's mod_autoindex.

=head1 CONFIGURATION

=over 4

=item root

 Document root directory. Defaults to the current directory.

 if root is a file, serve only root file.

=back

=head1 AUTHOR

hayajo

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
