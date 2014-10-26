package SWISH::Prog::Xapian;
use warnings;
use strict;

our $VERSION = '0.01';

=head1 NAME

SWISH::Prog::Xapian - Swish3 Xapian backend

=head1 SYNOPSIS

 # create an indexing program
 use SWISH::Prog;
 my $indexer = SWISH::Prog->new(
    invindex   => 'path/to/index.swish',
    aggregator => 'fs',
    indexer    => 'xapian',
    config     => 'path/to/swish.conf',
 );
 
 $indexer->index('path/to/files');
 
 # then search the index
 my $searcher = SWISH::Prog::Xapian::Searcher->new(
    invindex => 'path/to/index.swish',
    config   => 'path/to/swish.conf',
 );
 my $results = $searcher->search('my query')
 while ( my $result = $results->next ) {
    printf("%s : %s\n", $result->score, $result->uri);
 }

=head1 DESCRIPTION

SWISH::Prog::Xapian is a Xapian-based implementation of Swish3,
using the SWISH::3 bindings for libswish3.

See the Swish3 development site at http://dev.swish-e.org/wiki/swish3

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-swish-prog-xapian at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-Xapian>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::Xapian

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-Xapian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-Xapian>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Xapian>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-Xapian>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
