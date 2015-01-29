requires 'perl', '5.010001';

# requires 'Some::Module', 'VERSION';
requires 'Mojolicious', '>= 4.82';

on test => sub {
    requires 'Test::More', '0.88';
};
