package Bioinfo::App;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options;

# VERSION: 
# ABSTRACT: my perl module and CLIs for Biology

=head1 SYNOPSIS

  use Bioinfo;
  ...

=head1 DESCRIPTION

=cut

=head1 METHODS

=head2 execute

=cut

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  $self->options_usage unless (@$args_ref);
}

1;

