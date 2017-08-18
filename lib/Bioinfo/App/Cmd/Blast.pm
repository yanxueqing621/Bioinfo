package Bioinfo::App::Cmd::Blast;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options prefer_commandline => 1;

# VERSION: 
# ABSTRACT: various operator related to Blast+

=head1 SYNOPSIS

  use Bioinfo::App::Cmd::Blast;
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

