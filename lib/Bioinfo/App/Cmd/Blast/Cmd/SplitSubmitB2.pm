package Bioinfo::App::Cmd::Blast::Cmd::SplitSubmitB2;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options prefer_commandline => 1;
use IO::All;
use Bioinfo::PBS::Queue;

# VERSION: 
# ABSTRACT: submit blast after splitting a fasta file into multiple files;

=head1 SYNOPSIS

  use Bioinfo::App::Cmd::Blast::Cmd::SplitSubmit;
  Bioinfo::App::Cmd::Blast::Cmd::SplitSubmit->new_with_cmd;

  example:
  biotools blast splitsubmitb2 -c 1 -d /home/jiaoyuannian/yangbaixue/yxq/3.3.pep/t/tcu -i ./ -m 2 -p 7 -s 10 -n blastt

=head1 DESCRIPTION

this module splits a fasta file into multiple files, then submit these files on parallel.

=head1 ATTRIBUTES

=head2 indir

The input file is a file of fasta format

=cut

option indir => (
  is  => 'ro',
  required  => 1,
  format  => 's',
  short => 'i',
  doc => 'the dir include fasta format file'
);

=head2 split_num

number of files that the fasta file will be split

=cut

option split_num => (
  is  => 'ro',
  format  => 'i',
  short => 's',
  default => sub { '20' },
  doc => 'number of files that the fasta file will be split'
);

=head2 blast_cpu

the cpu number will be set on blast

=cut

option blast_cpu => (
  is => 'ro',
  format => 'i',
  short => 'c',
  default => sub { '8' },
  doc => 'cpu number will be used by blastp in each node of Cluster',
);

=head2 parallel_task_num

the task number will be running at the same time

=cut

option parallel_task_num => (
  is => 'ro',
  format => 'i',
  short => 'p',
  default => sub { '20' },
  doc => 'the task number will be running at the same time',
);

=head2 db

the database that blast will use

=cut

option db => (
  is  => 'rw',
  format => 's',
  short => 'd',
  default => sub { 'nr_plant' },
  doc => 'the database that blast will use, should be absolute path',
);

=head2 type

=cut

option type => (
  is  => 'rw',
  format => 's',
  short => 't',
  default => sub { 'pbs' },
  doc => "where the blast will be runned [local, pbs] default:pbs"
);

=head2 blast

the subcomand in blast+, such as [blastp blastx],default:blastp

=cut

option blast => (
  is => 'rw',
  format => 's',
  short => 'b',
  default => sub { 'blastp' },
  doc => 'which blast program will be used default:blastp',
);

=head2 queue_name

the name of PBS queue

=cut

option queue_name => (
  is => 'rw',
  format => 's',
  short => 'n',
  default => sub { 'blast_' . time },
  doc => 'which blast program will be used default:blastp',
);

=head2 max_target_seqs

the parameter used in blast

=cut

option max_target_seqs => (
  is => 'rw',
  format => 's',
  short => 'm',
  default => sub { 10 },
  doc => 'the parameter used in blast',
);

=head2 outfmt

parameter used in blast

=cut

option outfmt => (
  is => 'rw',
  format => 's',
  short => 'f',
  default => sub { 5 },
  doc => 'the parameter used in blast',
);

=head2 prefix

the prefix of the split file

=cut

option prefix => (
  is => 'ro',
  format => 's',
  short => 'x',
  default => sub { '' },
  doc => 'the prefix of the split file',
);


=head1 METHODS

=head2 execute

=cut

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  $self->options_usage unless (@$args_ref);
  my $indir = $self->indir;
  my $blast = $self->blast;
  my $cpu = $self->blast_cpu;
  my $parallel_task_num = $self->parallel_task_num;
  my $db = io($self->db)->absolute->pathname;
  my $queue_name = $self->queue_name;
  my $split_num = $self->split_num;
  my $prefix = $self->prefix;
  my $max_target_seqs = $self->max_target_seqs;
  my $outfmt = $self->outfmt;
  my @fa_dirs;

  my @io_fas = io($indir)->filter(sub {$_->filename =~/\.pep$|\.fa$|\.fasta$/})->all_files;
  my $pbs = Bioinfo::PBS::Queue->new( name => $queue_name,
                                      parallel => $parallel_task_num);

  for my $fa (@io_fas) {
    my $fa_name = $fa->filename;
    my $fa_name_short = $fa_name;
    $fa_name_short =~s/\.fa|\.pep|\.fasta//;

    push @fa_dirs, $fa_name_short;
    system("biotools fasta split -i $fa_name -n $split_num -o $fa_name_short");
    my $path = io("$fa_name_short")->absolute->pathname;
    for (my $i = 1; $i <= $split_num; $i++) {
      my $fasta = "$prefix$i.fa";
      my $cmd;
      if ($outfmt == 5) {
        #say "blast output mode: 5";
        my $outfile = "$fasta.xml";
        $cmd = "$blast -query $fasta -out $outfile -db $db -outfmt $outfmt  -evalue 1e-5 -num_threads $cpu -max_target_seqs $max_target_seqs";
        $cmd .= "\nbiotools blast parsexml -i $outfile -o $fasta.xls";
      } else {
        #say "blast output mode: 6";
        my $outfile = "$fasta.xls";
        $cmd = "$blast -query $fasta -out $outfile -db $db -outfmt $outfmt  -evalue 1e-5 -num_threads $cpu -max_target_seqs $max_target_seqs";
      }
      # say $cmd;
      my $para = {
        cpu => $cpu,
        name => $i,
        cmd => $cmd,
        path => $path,
      };
      $pbs->add_tasks($para);
    }
  }
  $pbs->execute;
  for my $dir (@fa_dirs) {
    system("cat $dir/*xls >$dir/$dir.xls")
    system("cat $dir/*xls.m8 >$dir/$dir.xls.m8")
  }
  say "finished";

}

1;
