package SWISH::Prog::Xapian::Indexer;
use strict;
use warnings;
use base qw( SWISH::Prog::Indexer );
use Carp;
use SWISH::Prog::Xapian::InvIndex;
use Search::Xapian::Document;
use Search::Xapian::TermGenerator;
use SWISH::3 qw(:constants);
use Scalar::Util qw( blessed );
use Data::Dump qw( dump );

our $VERSION = '0.01';

=head1 NAME

SWISH::Prog::Xapian::Indexer - Swish3 Xapian backend

=head1 SYNOPSIS

 TODO
 
=cut

=head1 METHODS

=head2 init

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # default config
    $self->{config} ||= SWISH::Prog::Config->new;

    # default index
    $self->{invindex} ||= SWISH::Prog::Xapian::InvIndex->new;

    if ( $self->{invindex} && !blessed( $self->{invindex} ) ) {
        $self->{invindex}
            = SWISH::Prog::Xapian::InvIndex->new( path => $self->{invindex} );
    }

    unless ( $self->invindex->isa('SWISH::Prog::Xapian::InvIndex') ) {
        croak ref($self)
            . " requires SWISH::Prog::Xapian::InvIndex-derived object";
    }

    $self->{flush} ||= 100000;

    # TODO XML-ify $self->{config} and pass in to parser too.
    $self->{parser} = SWISH::3->new( handler => sub { $self->_handler(@_) } );

    $self->{parser}->analyzer->set_tokenize(0);

    # so Headers uses correct version
    $ENV{SWISH3} = 1;

    return $self;

}

# trick is mapping between the basic SWISH::3::Doc structure
# and the Xapian::Document structure
# not much to it really: just save properties as 'value'
# and tokens as 'posting'
# swishdescription could be saved as 'data'
# uri gets saved as 'term' (xapian uses for unique id)

# set_data() can be used to store whatever you want
# but can't be sorted on. so it's like an unsortable property

# add_value() is similar to Swish-e properties
# results can be sorted by 'value'
# and each 'value' needs a unique number (like a property id)

# add_term() is where you would add a word with no positional info
# could have META: prefixed however and optional 'weight' as second param
# we use uri as unique term

# add_posting() is for adding specific words with positional info
# can take 'weight' as optional 3rd param
# we add twice so a word can be found 'naked' and with explicit metaname prefix

sub _handler {
    my ( $self, $data ) = @_;

    #warn "handler called";

    # MetaNames and PropertyNames may be added for each new doc.
    my $PropertyNames = $data->config->get_properties;
    my $MetaNames     = $data->config->get_metanames;
    my $PNames        = $PropertyNames->keys;
    my $MNames        = $MetaNames->keys;

    my $xdoc = Search::Xapian::Document->new
        or croak "can't create Search::Xapian::Document object";

    my $docinfo = $data->doc;

    # unique identifier
    my $uri = join( '', SWISH_PREFIX_URL(), $docinfo->uri );
    $xdoc->add_term($uri);
    $xdoc->add_term( join( '', SWISH_PREFIX_MTIME(), $docinfo->mtime ) );

    #warn "add $uri";

    # TODO add date parts as terms like swish_xapian.cpp does

    # data record like swish_xapian.cpp does
    my $record = join( "\n",
        'url=' . $docinfo->uri,
        'title='
            . ( join( "\n", @{ $data->properties->{'swishtitle'} } ) || '' ),
        'type=' . $docinfo->mime,
        'modtime=' . $docinfo->mtime,
        'size=' . $docinfo->size );
    $xdoc->set_data($record);

    # example
    #    for my $p (@$PNames) {
    #        my $prop     = $PropertyNames->get($p);
    #        my $property = {
    #            id          => $prop->id,
    #            name        => $prop->name,
    #            type        => $prop->type,
    #            ignore_case => $prop->ignore_case,
    #            verbatim    => $prop->verbatim,
    #
    #            #alias_for   => $prop->alias_for,
    #            max  => $prop->max,
    #            sort => $prop->sort,
    #        };
    #
    #    }
    #
    #    # same thing for MetaNames
    #    for my $m (@$MNames) {
    #        next if exists $self->{_metanames}->{$m};
    #        my $meta     = $MetaNames->get($m);
    #        my $metaname = {
    #            id   => $meta->id,
    #            name => $meta->name,
    #            bias => $meta->bias,
    #
    #            #alias_for => $m->alias_for
    #        };
    #    }

    # TODO add_posting() is the most intensive and should likely be XS-ified.
    # for now, use TermGenerator instead.
    # MAKE SURE TO TURN TOKENIZER OFF in parser,
    # since otherwise we tokenize 2x.

    # the TermGenerator tokenizes using the same algorithm as the QueryParser
    # http://thread.gmane.org/gmane.comp.search.xapian.general/6905/focus=6907
    my $analyzer = Search::Xapian::TermGenerator->new;
    $analyzer->set_document($xdoc);

    #warn "set document";

    my $metanames = $data->metanames;
    for my $metaname (@$MNames) {
        my $meta = $MetaNames->get($metaname);
        my $name = $meta->name;

        # TODO allow negative values
        my $weight = $meta->bias > 0 ? $meta->bias : 1;

        #warn "meta $name weight $weight";
        #warn dump $metanames->{$name};

        $analyzer->index_text(
            join( SWISH_TOKENPOS_BUMPER(), @{ $metanames->{$name} } ),
            $weight, $meta->id . ':' );

        # index swishdefault and swishtitle without any prefix as well
        if (   $name eq SWISH_DEFAULT_METANAME()
            or $name eq SWISH_TITLE_METANAME() )
        {
            $analyzer->index_text(
                join( SWISH_TOKENPOS_BUMPER(), @{ $metanames->{$name} } ),
                $weight );
        }

    }

    # add_value() is similar to Swish-e properties
    # results can be sorted by 'value'
    # and each 'value' needs a unique number (like a property id)
    for my $d ( SWISH_DOC_FIELDS() ) {
        next if $d eq 'ext';

        #warn "docinfo $d -> " . $docinfo->$d;
        $xdoc->add_value( SWISH_DOC_FIELDS_MAP()->{$d}, $docinfo->$d );
    }

    # ProperyNames
    my $properties = $data->properties;
    for my $prop_name (@$PNames) {
        my $prop_value = $properties->{$prop_name};
        my $prop_id    = $PropertyNames->get($prop_name)->id;

        #warn "prop $prop_name id $prop_id";
        #warn dump $prop_value;

        # TODO best way to join() ?
        $xdoc->add_value( $prop_id, join( "\n", @$prop_value ) );

        #warn "add_value $prop_id";
    }

    #warn "xdoc prepped";

    my $action = $docinfo->action || 'add_or_update';
    my $method = '_' . $action;

    #warn "$method on $uri";
    my $doc_id = $self->$method( $xdoc, $uri );    # TODO stash doc_id?

}

=head2 process

=cut

sub process {
    my $self = shift;
    my $sdoc = $self->SUPER::process(@_);
    $self->{parser}->parse_buffer("$sdoc");
    if ( $self->count > $self->flush ) {
        $self->invindex->xdb->flush;
    }
    return $sdoc;
}

sub _add_or_update {
    my ( $self, $xdoc, $uri ) = @_;

    if ( $self->invindex->xdb->term_exists($uri) ) {
        return $self->_update( $xdoc, $uri );
    }
    else {
        return $self->_add($xdoc);
    }
}

sub _add {
    my ( $self, $xdoc, $uri ) = @_;
    return $self->invindex->xdb->add_document($xdoc);
}

sub _update {
    my ( $self, $xdoc, $uri ) = @_;
    my $doc_id = $self->invindex->xdb->postlist_begin($uri)
        or croak "no such doc in index $self->{invindex}: $uri";

    $self->invindex->xdb->replace_document( $doc_id, $xdoc );
    return $doc_id;
}

sub _delete {
    my ( $self, $xdoc, $uri ) = @_;
    my $doc_id = $self->invindex->xdb->postlist_begin($uri)
        or croak "no such doc in index: $uri";

    $self->invindex->xdb->delete_document($doc_id);
    return $doc_id;
}

=head2 finish

Calls SUPER::finish() and sets the internal SWISH::3 parser object to undef
in order to avoid spurious memory warnings during Perl's garbage collection.

=cut

sub finish {
    my $self = shift;

    # write header
    my $index = $self->{parser}->config->get_index;

    $index->set( 'Format', 'Xapian' );

    #$self->{parser}->config->set_index($index);

    $self->{parser}->config->write(
        $self->invindex->path->file( SWISH_HEADER_FILE() )->stringify );

    $self->{parser} = undef;    # just to avoid mem leak warnings

    $self->SUPER::finish(@_);
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
