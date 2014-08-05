use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::File::FromCode::JSON;

our $VERSION = '0.001000';

# ABSTRACT: A container for arbitrary data that JSONifies on demand.

# AUTHORITY

use Moose;
extends 'Dist::Zilla::File::FromCode';

=attr C<data_code>

B<REQUIRED:> A C<CodeRef> that returns I<initial> data.

=cut

use Module::Runtime qw( require_module );

has 'data_code'          => ( isa => 'CodeRef',  is => ro =>, required   => 1 );
has '_json_data_mungers' => ( isa => 'ArrayRef', is => ro =>, lazy_build => 1 );
has 'serializer_class'   => ( isa => 'Str',      is => rw =>, default    => sub { 'JSON' } );
has '+code' => ( init_arg => undef, required => 0, lazy_build => 1 );

sub _build__json_data_mungers { [] }

sub _munge_json {
  my ($self) = @_;

  my $data = $self->json_data_code->();

  require_module( $self->serializer_class );

  my $serializer = $self->serializer_class->new();

  for my $munger ( @{ $self->_json_data_mungers } ) {
    my ( $adder, $code ) = @{$munger};
    my $new_data = $code->( $data, $serializer );
    if ( not defined $new_data ) {
      die "$adders 's munger returned undef";
    }
    $data = $new_data;
  }
  return $serializer->encode($data);
}

sub _build_code {
  my ($self) = @_;
  return sub { $self->_munge_json };
}

sub add_json_munger {
  my ( $self, $code ) = @_;
  my $class = caller();
  push @{ $self->_json_data_mungers }, [ $class, $code ];
}

sub convert {
  my ( $class, $other ) = @_;
  die "I don't know what I should be doing here";
  return $other if $other->isa(__PACKAGE__);
  if ( $other->isa('Dist::Zilla::File::FromCode') ) {
    ### I Don't know what I'm doing
    # maybe load some JSON class and decode? but how to we deal with ->return_encoding!?!?
    # fffuuuuu
  }
  ## and static files? Ugh.
}

sub convert_in_place {
  my ( $class, $zilla, $other ) = @_;
  die "This shit is superimpossiburu hard to do right";
  return $other if $other->isa(__PACKAGE__);
  ## Do we mangle the hash ref directly? Do we nuke the file from $zilla->files by abusing the array its in?
  ## SO CONFUSE.
  ## Would be much easier if files were added to tree in their  right type but ERMAGERD wont happen.
  if ( $other->isa('Dist::Zilla::File::FromCode') ) {
    ### I Don't know what I'm doing
  }
}

=head1 SYNOPSIS

=head2 Creating

  use Dist::Zilla::File::FromCode::JSON;

  my $file = Dist::Zilla::File::FromCode::JSON->new(
      data_code => sub {
        # lazy
        return { some, data, structure, here };
      },
  );
  ...
  $self->add($file);

=head2 Munging as Data

In a munger:

  if ( $file->isa('Dist::Zilla::File::FromCode::JSON') ) {
    $file->add_json_munger(sub {
      my ( $data ) = shift; ### Get data
      # modify $data
      return $data; #### IMPORTANT #####
    });
  }

=head2 Munging as Text

    my $code = $file->code;
    $file->code(sub {
       my $content = $code->();
       # twiddle $content
       return $content;
    });

=head2 Serializing

  $file->encoded_content(); # json byte stream.

=head2 Converting from existing C<File> nodes

  my $file = Dist::Zilla::File::FromCode::JSON->convert( $old_file );

=head2 Converting from existing C<File> nodes in-place.

  for my $file ( @{ $zilla->files }) {
    Dist::Zilla::File::FromCode::JSON->convert_in_place( $zilla, $file );
    $file->add_json_munger(sub {

    });
  }

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
