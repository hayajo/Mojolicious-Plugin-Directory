package Mojolicious::Plugin::Directory;
use strict;
use warnings;
our $VERSION = '0.07';

use Cwd ();
use Encode ();
use DirHandle;
use Mojo::Base qw{ Mojolicious::Plugin };
use Mojolicious::Types;

# Stolen from Plack::App::Direcotry
my $dir_page = <<'PAGE';
<html><head>
  <title>Index of <%= $current %></title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
<h1>Index of <%= $current %></h1>
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

my $types = Mojolicious::Types->new;

sub register {
    my ( $self, $app, $args ) = @_;

    my $root        = Mojo::Home->new( $args->{root} || Cwd::getcwd );
    my $handler     = $args->{handler};
    my $index       = $args->{dir_index};
    my $enable_json = $args->{enable_json};

    my $render_opts = $args->{render_opts} || {};
    if ( my $template = $args->{dir_template} ) {
        $render_opts->{template} = $template;
    }
    else {
        $render_opts->{inline} = $args->{dir_page} || $dir_page;
    }

    $app->hook(
        before_dispatch => sub {
            my $c = shift;

            return render_file( $c, $root ) if ( -f $root->to_string() );

            my $path = $root->rel_dir( Mojo::Util::url_unescape( $c->req->url->path ) );
            $handler->( $c, $path ) if ( ref $handler eq 'CODE' );

            if ( -f $path ) {
                render_file( $c, $path ) unless ( $c->tx->res->code );
            }
            elsif ( -d $path ) {
                if ( $index && ( my $file = locate_index( $index, $path ) ) ) {
                    return render_file( $c, $file );
                }

                render_indexes( $c, $path, $render_opts, $enable_json )
                    unless ( $c->tx->res->code );
            }
        },
    );
    return $app;
}

sub locate_index {
    my $index = shift || return;
    my $dir   = shift || Cwd::getcwd;

    my $root  = Mojo::Home->new($dir);

    $index = ( ref $index eq 'ARRAY' ) ? $index : ["$index"];
    for (@$index) {
        my $path = $root->rel_file($_);
        return $path if ( -e $path );
    }
}

sub render_file {
    my ( $c, $file ) = @_;

    my $data = Mojo::Util::slurp($file);
    $c->render( data => $data, format => get_ext($file) || 'txt' );
}

sub render_indexes {
    my ( $c, $dir, $render_opts, $enable_json ) = @_;

    my @files =
        ( $c->req->url eq '/' )
        ? ()
        : ( { url => '../', name => 'Parent Directory', size => '', type => '', mtime => '' } );

    my ( $current, $list ) = list_files( $c, $dir );
    push @files, @$list;

    $c->stash( files   => \@files );
    $c->stash( current => $current );

    my %respond = ( any => $render_opts );
    $respond{json} = { json => { files => \@files, current => $current } }
        if ($enable_json);

    $c->respond_to(%respond);
}

sub list_files {
    my ( $c, $dir ) = @_;

    my $current = Encode::decode_utf8( Mojo::Util::url_unescape( $c->req->url->path ) );

    return ( $current, [] ) unless $dir;

    my $dh = DirHandle->new($dir);
    my @children;
    while ( defined( my $ent = $dh->read ) ) {
        next if $ent eq '.' or $ent eq '..';
        push @children, Encode::decode_utf8($ent);
    }

    my @files;
    for my $basename ( sort { $a cmp $b } @children ) {
        my $file = "$dir/$basename";
        my $url  = Mojo::Path->new($current)->trailing_slash(0);
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

    return ( $current, \@files );
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

  # simple usage
  use Mojolicious::Lite;
  plugin( 'Directory', root => "/path/to/htdocs" )->start;

  # with handler
  use Text::Markdown qw{ markdown };
  use Path::Class;
  use Encode qw{ decode_utf8 };
  plugin('Directory', root => "/path/to/htdocs", handler => sub {
      my ($c, $path) = @_;
      if ( -f $path && $path =~ /\.(md|mkdn)$/ ) {
          my $text = file($path)->slurp;
          my $html = markdown( decode_utf8($text) );
          $c->render( inline => $html );
      }
  })->start;

  or

  > perl -Mojo -E 'a->plugin("Directory", root => "/path/to/htdocs")->start' daemon

=head1 DESCRIPTION

L<Mojolicious::Plugin::Directory> is a static file server directory index a la Apache's mod_autoindex.

=head1 METHODS

L<Mojolicious::Plugin::Directory> inherits all methods from L<Mojolicious::Plugin>.

=head1 OPTIONS

L<Mojolicious::Plugin::Directory> supports the following options.

=head2 C<root>

  # Mojolicious::Lite
  plugin Directory => { root => "/path/to/htdocs" };

Document root directory. Defaults to the current directory.

if root is a file, serve only root file.

=head2 C<dir_index>

  # Mojolicious::Lite
  plugin Directory => { dir_index => [qw/index.html index.htm/] };

like a Apache's DirectoryIndex directive.

=head2 C<dir_page>

  # Mojolicious::Lite
  plugin Directory => { dir_page => $template_str };

a HTML template of index page

=head2 C<dir_template>

  # Mojolicious::Lite
  plugin Directory => { dir_template => $template_name };

  # plugin Directory => {
  #     dir_template => $template_name,
  #     render_opts => { format => 'html', handler => 'ep' },
  # };

a template of index page.

This option takes precedence over the C<dir_page>.

=head2 C<handler>

  # Mojolicious::Lite
  use Text::Markdown qw{ markdown };
  use Path::Class;
  use Encode qw{ decode_utf8 };
  plugin Directory => {
      handler => sub {
          my ($c, $path) = @_;
          if ($path =~ /\.(md|mkdn)$/) {
              my $text = file($path)->slurp;
              my $html = markdown( decode_utf8($text) );
              $c->render( inline => $html );
          }
      }
  };

CODEREF for handle a request file.

if not rendered in CODEREF, serve as static file.

=head2 C<enable_json>

enable json response.

  # http://localhost/directory?format=json
  plugin Directory => { enable_json => 1 };

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 SEE ALSO

L<Plack::App::Directory>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
