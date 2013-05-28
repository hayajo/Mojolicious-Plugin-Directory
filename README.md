# NAME

Mojolicious::Plugin::Directory - Serve static files from document root with directory index

# SYNOPSIS

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

# DESCRIPTION

[Mojolicious::Plugin::Directory](http://search.cpan.org/perldoc?Mojolicious::Plugin::Directory) is a static file server directory index a la Apache's mod\_autoindex.

# METHODS

[Mojolicious::Plugin::Directory](http://search.cpan.org/perldoc?Mojolicious::Plugin::Directory) inherits all methods from [Mojolicious::Plugin](http://search.cpan.org/perldoc?Mojolicious::Plugin).

# OPTIONS

[Mojolicious::Plugin::Directory](http://search.cpan.org/perldoc?Mojolicious::Plugin::Directory) supports the following options.

## `root`

    # Mojolicious::Lite
    plugin Directory => { root => "/path/to/htdocs" };

Document root directory. Defaults to the current directory.

if root is a file, serve only root file.

## `dir_index`

    # Mojolicious::Lite
    plugin Directory => { dir_index => [qw/index.html index.htm/] };

like a Apache's DirectoryIndex directive.

## `dir_page`

    # Mojolicious::Lite
    plugin Directory => { dir_page => $template_str };

a HTML template of index page

## `dir_template`

    # Mojolicious::Lite
    plugin Directory => { dir_template => $template_name };

    # plugin Directory => {
    #     dir_template => $template_name,
    #     render_opts => { format => 'html', handler => 'ep' },
    # };

a template of index page.

This option takes precedence over the `dir_page`.

## `handler`

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

## `enable_json`

enable json response.

    > curl http://localhost/directory?format=json

# AUTHOR

hayajo <hayajo@cpan.org>

# SEE ALSO

[Plack::App::Directory](http://search.cpan.org/perldoc?Plack::App::Directory)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
