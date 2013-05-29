# NAME

Mojolicious::Plugin::Directory - Serve static files from document root with directory index

# SYNOPSIS

    use Mojolicious::Lite;
    plugin 'Directory';
    app->start;

or

    > perl -Mojo -E 'a->plugin("Directory")->start' daemon

# DESCRIPTION

[Mojolicious::Plugin::Directory](http://search.cpan.org/perldoc?Mojolicious::Plugin::Directory) is a static file server directory index a la Apache's mod\_autoindex.

# METHODS

[Mojolicious::Plugin::Directory](http://search.cpan.org/perldoc?Mojolicious::Plugin::Directory) inherits all methods from [Mojolicious::Plugin](http://search.cpan.org/perldoc?Mojolicious::Plugin).

# OPTIONS

[Mojolicious::Plugin::Directory](http://search.cpan.org/perldoc?Mojolicious::Plugin::Directory) supports the following options.

## `root`

    plugin Directory => { root => "/path/to/htdocs" };

Document root directory. Defaults to the current directory.

if root is a file, serve only root file.

## `dir_index`

    plugin Directory => { dir_index => [qw/index.html index.htm/] };

like a Apache's DirectoryIndex directive.

## `dir_page`

    my $template_str = <<EOT
    <!DOCTYPE html>
    <html lang="ja">
    ...
    </html>
    EOT

    plugin Directory => { dir_page => $template_str };

a HTML template of index page.

"$files" and "$current" are passed in stash.

- $files: Array\[Hash\]

    list of files and directories

- $current: String

    current path

## `dir_template`

    plugin Directory => { dir_template => 'index' };

    # with 'render_opts' option
    plugin Directory => {
        dir_template => 'index',
        render_opts  => { format => 'html', handler => 'ep' },
    };

    ...

    __DATA__

    @@ index.html.ep
    % layout 'default';
    % title 'DirectoryIndex';
    <h1>Index of <%= $current %></h1>
    <ul>
    % for my $file (@$files) {
    <li><a href='<%= $file->{url} %>'><%== $file->{name} %></a></li>
    % }

    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <html>
      <head><title><%= title %></title></head>
      <body><%= content %></body>
    </html>

a template name of index page.

this option takes precedence over the `dir_page`.

"$files" and "$current" are passed in stash.

- $files: Array\[Hash\]

    list of files and directories

- $current: String

    current path

## `handler`

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

    # http://host/directory?format=json
    plugin Directory => { enable_json => 1 };

enable json response.

# AUTHOR

hayajo <hayajo@cpan.org>

# SEE ALSO

[Plack::App::Directory](http://search.cpan.org/perldoc?Plack::App::Directory)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
