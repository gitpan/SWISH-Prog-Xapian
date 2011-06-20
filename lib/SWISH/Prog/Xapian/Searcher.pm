package SWISH::Prog::Xapian::Searcher;
use strict;
use warnings;
use base qw( SWISH::Prog::Searcher );
use Carp;
use SWISH::Prog::Xapian::Results;

our $VERSION = '0.05';

=head1 NAME

SWISH::Prog::Xapian::Searcher - Swish3 Xapian backend Searcher

=head1 SYNOPSIS

 # see SWISH::Prog::Searcher
 
=cut

=head1 DESCRIPTION

SWISH::Prog::Xapian::Searcher is not made to replace the more fully-featured
Search::Xapian. Instead, SWISH::Prog::Xapian::Searcher
provides a simple API similar to other SWISH::Prog::Searcher-based backends
so that you can experiment with alternate
storage engines without needing to change much code.
When your search application requirements become more complex, the author
recommends the switch to using Search::Xapian directly.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Searcher> documentation.

=cut

=head2 search( I<query> [, I<opts> ] )

Returns a SWISH::Prog::Xapian::Results object.

I<opts> is an optional hashref with the following supported
key/values:

=over

=item start

The starting position. Default is 0.

=item max

The ending position. Default is max_hits().

=item order

The sort order. Default is by score.
B<This feature is not yet supported.>

=back

=cut

sub search {
    my $self  = shift;
    my $query = shift;
    croak "query required" unless defined $query;
    my $opts = shift || {};

    my $start = $opts->{start} || 0;
    my $max   = $opts->{max}   || $self->max_hits;
    my $order = $opts->{order} || 'score';

    #warn Data::Dump::dump $self;

    # we enquire on one db but can span multiple.
    my $db1 = $self->{invindex}->[0]->{xdb};
    for my $xdb ( map { $_->{xdb} } ( @{ $self->{invindex} } )[ 1 .. -1 ] ) {
        $db1->add_database($xdb);
    }
    my $enq = $db1->enquire($query);
    if ( $order ne 'score' ) {
        croak "sort order by anything other than score is not yet supported";
    }
    my $mset = $enq->get_mset( $start, $max );
    my $results = SWISH::Prog::Xapian::Results->new(
        hits => $mset->size(),
        mset => $mset,
    );
    $results->{_i} = 0;
    return $results;
}

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
