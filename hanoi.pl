#!/usr/bin/env perl
#
# Tower of Hanoi puzzle.
# There are 3 towers / pegs - source, spare / middle and destination.
# Multiple disks of different sizes are stacked on the source peg,
# from the largest on the bottom, to the smallest on the top.
# The goal of the game is to move all the disks over to the destination tower,
# using the spare peg for swapping the disks.
# NOTE: You cannot place larger disk onto a smaller disk.
# Formula for minimum # of moves needed to solve the puzzle:
#    m = 2^d - 1
# Where:
#    m - # of moves
#    d - # of disks
#

use strict;
use warnings;

my (@tower1, @tower2, @tower3);
my @towers = (\@tower1, \@tower2, \@tower3);
my $disks = 3;
my $src = 1;
my $mid = 2;
my $dst = 3;
my $moves = 0;
my $method = 0; # 0 - recursive / 1 - BFS iterative / 2 - interactive

sub Usage
{
   CopyrightNotice();
   print "https://en.wikipedia.org/wiki/Tower_of_Hanoi\n";
   print "Usage:\n";
   print "   hanoi.pl src spare dest disks [method]\n";
   print "Where:\n";
   print "   src, spare, dest - tower# (1..3), must be 3 different numbers,\n";
   print "   disks            - number of disks (must be greater than 0),\n";
   print "   method           - 0: recursive (default) / 1: BFS iterative /\n";
   print "                      2: interactive.\n";
}

sub ValidateArgs
{
   return (defined $src and defined $mid and defined $dst and 
           $src > 0 and $src < 4 and
           $mid > 0 and $mid < 4 and
           $dst > 0 and $dst < 4 and
           $dst != $src and $dst != $mid and $src != $mid and
           $disks > 0);
}

#
# Display current towers / disks configuration.
#
sub ShowTowers
{
   my $width = $disks * 2;
   print "\n";
   for (my $i = $disks - 1; $i >= 0; $i--) {
      for (my $twr = 0; $twr < 3; $twr++) {
         my $disk = $towers[$twr][$i + 1]; 
         my $b = $disks - $disk;
         my $e = $width - $b - 1;

         for (my $cur = 0; $cur < $width; $cur++) {
            if ($cur >= $b and $cur <= $e) {
               print "#";
            } else {
               print ".";
            }
         }
         print "  ";
      }
      print "\n";
   }
   print "\n";
}

#
# Check if puzzle is solved.
#
sub IsSolved
{
   my $solved = 1;
   for(my $i = 0; $i < $disks; $i++) {
      if ($towers[$dst - 1][$i + 1] != $disks - $i) {
         $solved = 0;
      }
   }
   return $solved;
}

#
# Perform disk move from source to destination if requested move is valid.
# Valid move conditions:
#  - disk is present on the source tower,
#  - there is no disk on the destination tower OR the disk on the destination
#    tower is larger than the disk being moved on top of it from the source
#    tower.
# Display towers state.
# NOTE: Displaying of towers state is inhibited, when $noshow argument
#       is passed and is greater than 0 OR when the requested move is
#       invalid.
# Return the state string after move OR empty string if the requested move
# was invalid.
# 
sub MoveDisk
{
   my ($src, $dst, $noshow) = @_;
   return "" if (0 >= $src or 0 >= $dst or 3 < $src or 3 < $dst);
   $noshow = 0 if (not defined $noshow);
   my $retstate = "";
   my $bkpstate = GetStateStr();
   my $d = 0;
   my $moved = 0;
   for (my $i = $disks; $i > 0; $i--) {
      $d = $towers[$src - 1][$i];
      if (0 < $d) { # non-empty slot - a disk exists
         $towers[$src - 1][$i] = 0;
         last;
      }
   }
   if (0 < $d) { # can only move existing disk
      for (my $i = 1; $i <= $disks; $i++) {
         if (0 == $towers[$dst - 1][$i]) { # can only move to empty slot
            # can only move disk over on top of the larger disk
            if (1 == $i or (1 < $i and $d < $towers[$dst - 1][$i - 1])) {
               $towers[$dst - 1][$i] = $d;
               $retstate = GetStateStr();
               $moves++;
               if (!$noshow) {
                  print "$moves) Move $src to $dst.\n";
                  ShowTowers;
               }
               ++$moved;
               last;
            }
         }
      }
   }
   SetState($bkpstate) if (!$moved); # restore state if move could not be done
   return $retstate;
}

#
# Recursive solution to Hanoi Towers Puzzle:
# If there is just one disk to move, move it from source peg (tower)
# to the destination peg.
# Otherwise (more than one disk):
# 1) Move all the disks except the largest one to the spare peg.
#    Use the destination peg as a swap / spare.
# 2) Move the largest disk to the destination peg.
# 3) Move the disks from spare peg to the destination peg.
#    Use the source peg as a swap / spare.
#
sub Hanoi
{
   my ($peg_from, $peg_spare, $peg_to, $disk) = @_;
   if (1 == $disk) {
      MoveDisk($peg_from, $peg_to);
   } else {
      Hanoi($peg_from, $peg_to, $peg_spare, $disk - 1);
      MoveDisk($peg_from, $peg_to);
      Hanoi($peg_spare, $peg_from, $peg_to, $disk - 1);
   }
}

#
# Convert current disks configuration into a string in following format:
# (disk1,disk2,...,dishN,)(disk1,disk2,...,diskN,)(disk1,disk2,...,diskN,)
# Where the first set of parentheses contains disks on tower 1, 2nd set
# of parens has disks on tower 2 and 3rd has disks on tower 3.
#
sub GetStateStr
{
   my $retstate = "";
   for (my $twr = 0; $twr < 3; $twr++) {
      $retstate = $retstate . "(";
      for (my $disk = 1; $disk <= $disks; $disk++) {
         $retstate = $retstate . $towers[$twr][$disk] . ",";
      }
      $retstate = $retstate . ")";
   }
   return $retstate;
}

#
# Set current disks configuration based on string-format state:
# (disk1,disk2,...,dishN,)(disk1,disk2,...,diskN,)(disk1,disk2,...,diskN,)
# See description of GetStateStr subroutine.
#
sub SetState
{
   my ($state) = @_;
   my $mode = 1;
   my $numstr;
   my $disk = 0;
   my $twr = 0;
   my $idx = 1;

   # mode:
   # 1 - limbo
   # 2 - inside parentheses ()
 
   while ($state =~ /(.)/g) {
      if ($mode == 1 and $1 eq "(") {
         $mode = 2;
         $numstr = "";
         next;
      }
      if ($mode == 2 and $1 eq ",") {
         $disk = int($numstr);
         $towers[$twr][$idx] = $disk;
         $numstr = "";
         $idx++;
         next;
      } elsif ($mode == 2 and $1 eq ")") {
         $mode = 1;
         $twr++;
         last if ($twr > 2);
         $idx = 1;
         next;
      } else {
         $numstr = $numstr . $1;
      }
   }
}

#
# Return state of solved puzzle in string format, based on puzzle
# starting arguments (source, spare, destination pegs, # of disks).
#
sub GetSolvedStateStr
{
   my $savestate = GetStateStr();

   for (my $i = 1; $i <= $disks; $i++) {
      $towers[$dst - 1][$i] = $disks - $i + 1;
      $towers[$mid - 1][$i] = 0;
      $towers[$src - 1][$i] = 0;
   }

   my $retstate = GetStateStr();
   SetState($savestate);

   return $retstate;
}

#
# Iterative solution to Hanoi Towers Puzzle.
# Breadth-first search, backtracking from solved state to start state
# with index.
#
sub HanoiBFSIter
{
   my @all_states = ();
   my @bt_index = ();
   my $solved = GetSolvedStateStr();
   my $start = GetStateStr();
   my %seen = ();
   my $idx = -1;
   my @branches = ([1,2], [1,3], [2,1], [2,3], [3,1], [3,2]);

   print "Searching...\n";
   for (my ($i, $state) = (0, $solved);
        $state ne $start;
        $i++, $state = $all_states[$i]) {

      print "States checked: $i\r";
      for (my $v = 0; $v < 6; $v++) {
         SetState($state);
         my $move = MoveDisk($branches[$v][0], $branches[$v][1], 1);
         
         if ($move ne "" and not defined($seen{$move})) {
            $seen{$move} = $move;
            push(@all_states, $move);
            push(@bt_index, $i);

            if ($move eq $start) {
               $idx = $i;
               last;
            }
         }
      }
   }
   print "\n";
   $moves = 0;
   if ($idx >= 0) {

      print "Path to solution found.\n\n";
      for (my $i = $idx; $i > 0; $i = $bt_index[$i]) {
         $moves++;
         print "$moves)\n";
         SetState($all_states[$i]);
         ShowTowers;
      }
      $moves++;
      print "$moves)\n";
      SetState($solved);
      ShowTowers;

   }
}

#
# Solve puzzle manually / interactive mode.
#
sub HanoiPlay
{
   my $start = GetStateStr();

   print "Use following format for commands:\n";
   print "   PEG#[SPACE]PEG# - to move disk from peg to peg,\n";
   print "   Q|q - to quit.\n";
   print "   R|r - to reset.\n";
   print "Invalid commands will be ignored.\n";
   print "\n";

   while (!IsSolved()) {
      print "Disk move (from to) > ";
      chomp (my $cmd = <STDIN>);
      if ("q" eq $cmd or "Q" eq $cmd) {
         last;
      } elsif ("r" eq $cmd or "R" eq $cmd) {
         SetState($start);
         $moves = 0;
         print "\nPuzzle has been reset.\n";
         ShowTowers;      
      } else {
         my @move = split ' ', $cmd;
         if (defined($move[0]) and defined($move[1])) {
            my $from = int($move[0]);
            my $to = int($move[1]);
            MoveDisk($from, $to);
         }
      }
   }
   if (2**$disks - 1 == $moves) {
      print "Well done!\n";
   }
}

sub CopyrightNotice
{
   print "\nTower Of Hanoi Puzzle Solver.\n";
   print "(C) Marek Karcz 2023. All right reserved.\n";
   print "Free for personal and educational use.\n";
}

sub Main
{
   my ($from_tower, $mid_tower, $to_tower, $num_disks, $method) = @_;
   $method = 0 if (not defined $method);
   $src = $from_tower;
   $mid = $mid_tower;
   $dst = $to_tower;
   $disks = $num_disks;
   ValidateArgs() or Usage() and die;
   for (my $i = 0; $i <= $disks; $i++) {
      push(@{$towers[$src - 1]}, $disks - $i + 1);
      push(@{$towers[$mid - 1]}, 0);
      push(@{$towers[$dst - 1]}, 0);
   }
   CopyrightNotice();
   print "Goal - move the disks from peg $src to peg $dst.\n";
   print "Use peg $mid as spare.\n";
   print "You cannot put larger disk on top of the smaller one.\n";
   ShowTowers;
   if (0 == $method) {
      Hanoi($src, $mid, $dst, $disks);
   } elsif (1 == $method) {
      HanoiBFSIter;
   } else {
      HanoiPlay;
   }
   IsSolved() or die "Not solved.\n";
   print "Solved in $moves ";
   if ($moves > 1) {
      print "moves!\n";
   } else {
      print "move!\n";
   }
   if ($moves > 2**$disks - 1) {
       print "NOTE:\n";
       print "Solution is suboptimal.\n";
       print "Optimal solution for this configuration -";
       print " " . (2**$disks - 1) . " moves.\n";
   }
}

Main @ARGV
