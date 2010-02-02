package SWISH::Prog::Xapian::Result;
use strict;
use warnings;
use base qw( SWISH::Prog::Result );
use SWISH::3 ':constants';

our $VERSION = '0.04';

=head1 NAME

SWISH::Prog::Xapian::Result - search result for Swish3 Xapian backend

=head1 SYNOPSIS

 # see SWISH::Prog::Result
 
=cut

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Result> documentation.

=cut

=head2 uri

Returns the uri (unique term) for the result document.

=cut

sub uri { $_[0]->{doc}->get_value( SWISH_DOC_FIELDS_MAP()->{uri} ) }

=head2 title

Returns the title of the result document.

=cut

sub title { $_[0]->{doc}->get_value( SWISH_DOC_FIELDS_MAP()->{title} ) }

1;

__END__

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

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

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
