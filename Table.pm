package Tk::DBI::Table;
#------------------------------------------------
# automagically updated versioning variables -- CVS modifies these!
#------------------------------------------------
our $Revision           = '$Revision: 1.3 $';
our $CheckinDate        = '$Date: 2003/04/03 15:39:27 $';
our $CheckinUser        = '$Author: xpix $';
# we need to clean these up right here
$Revision               =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinDate            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinUser            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
#-------------------------------------------------
#-- package Tk::DBI::Table -----------------------
#-------------------------------------------------

=head1 NAME

Tk::DBI::Table - Megawidget to display a sql-Statement in HList.

=head1 SYNOPSIS

	use Tk;
	use Tk::DBI::Table;
	
	my $top = MainWindow->new;
	my $tkdbi = $top->DBITable(
			-sql		=> 'select * from table',
			-dbh   		=> $dbh,
			-display_id	=> 0,
		    )->pack(expand => 1, -fill => 'both');
	
	MainLoop;

=head1 DESCRIPTION

This is a megawidget to display a sql statement from your database. 
The features are:
- every column has a ResizeButton for flexible width
- The user can activate every Button and this will sort the column in the
direction 'ASC', 'Desc' or 'None'.

=cut

use Tk::HList;
use Tk::Compound;

# Special Module
eval('use Tk::ResizeButton;');
my $ERR = 1 if($@);
warn $@ if($@);

use base qw/Tk::Derived Tk::Frame/;

use strict;

Construct Tk::Widget 'DBITable';

my ($BITMAPDOWN, $BITMAPUP);

# ------------------------------------------
sub ClassInit
# ------------------------------------------
{
	my($class,$mw) = @_;

	unless(defined($BITMAPDOWN))
	{
		$BITMAPUP = __PACKAGE__ . "::uparrwow";
		my $bits_up = pack("b10"x10,
				"..........",
				"..........",
				"..........",
				".....#....",
				"....###...",
				"...#####..",
				"..#######.",
				".#########",
				"..........",
				".........."
				);
		$mw->DefineBitmap($BITMAPUP => 10,10, $bits_up);

		$BITMAPDOWN = __PACKAGE__ . "::downarrwow";
		my $bits_down = pack("b10"x10,
				"..........",
				"..........",
				"..........",
				".#########",
				"..#######.",
				"...#####..",
				"....###...",
				".....#....",
				"..........",
				".........."
				);
		$mw->DefineBitmap($BITMAPDOWN => 10,10, $bits_down);

	}
}


# ------------------------------------------
sub Populate {
# ------------------------------------------
	my ($obj, $args) = @_;

=head1 WIDGET-SPECIFIC OPTIONS

=head2 -dbh => $dbh

A database handle, this will return a error if not defined.

=cut

	$obj->{dbh} 		= delete $args->{'-dbh'} 	|| return $obj->error("No DB-Handle!");

=head2 -sql => 'select * from table'

A statement, this will return a error if not defined.

=cut

	$obj->{sql}		= delete $args->{'-sql'} 	|| return $obj->error("No SQL-Stm!");

=head2 -debug [I<0>|1]

This is a switch for debug output to the normal console (STDOUT)

=cut

	$obj->{debug} 		= delete $args->{'-debug'} 	|| 0;

=head2 -display_id [I<Off>|On]

This is a switch for displaying the id column.

=cut

	$obj->{display_id}	= delete $args->{'-display_id'} || 0;

=head2 -columnWidths [colWidth_0, colWidth_1, colWidth_2, ...]

Default width for field columns.

=cut

	$obj->{columnWidths}	= delete $args->{'-columnWidths'};

=head2 -srtColumnStyle(option => value)

Style for sorted column.

=cut

	$obj->{srtColumnStyle}	= delete $args->{'-srtColumnStyle'};

	$obj->SUPER::Populate($args);

=head1 METHODS

These are the methods you can use with this Widget.

=cut

	my %specs;

=head2 $dbitable->refresh( [to_sort_col_number] );

Refresh the table and sort (optional) the col number.

=cut


	$specs{-refresh} 	= [qw/METHOD  refresh      Refresh/,   		undef];

=head2 $dbitable->sortcol( to_sort_col_number );

Refresh the table and sort the col number or return the actually col sort number.

=cut

	$specs{-sortcol} 	= [qw/METHOD  sortcol      SortCol/,   		undef];

=head2 $dbitable->direction( ['NONE', 'ASC' or 'DESC'] );

Give a new direction. no parameter will return the actually direction.

=cut

	$specs{-direction} 	= [qw/METHOD  direction    Direction/,		'NONE'];
	
        $obj->ConfigSpecs(%specs);

	$obj->refresh();

} # end Populate


# Class private methods;
# ------------------------------------------
sub refresh {
# ------------------------------------------
	my $obj = shift or return warn("No object");
	my $sortcolumn = shift;

	$obj->toogle_direction($sortcolumn) 
		if(defined $sortcolumn);

	# get data
	$obj->{data} = my $data = $obj->getSql($obj->{sql}) 
		or return $obj->error('Problem in getSql');  
        my @fields = @{$obj->{fields}};

	# Create HList
	unless(defined $obj->{table}) {
		my $cols = scalar @fields;

		$obj->{table} = $obj->Scrolled('HList',
			-scrollbars 	=> 'osoe',
			-columns	=> $cols,
			-header		=> 1,
		)->pack(-expand => 1,
			-fill => 'both');
	
		$obj->Advertise("table" => $obj->{table});   #TEXT PART.
	}
	
	my $hl = $obj->{table};

	# create header
	my $c = -1;
	foreach my $field (@fields) {
		$c++;
		unless($ERR) {
			$obj->{header}->{$c} = $hl->ResizeButton( 
			  -relief 	=> 'flat', 
			  -anchor	=> 'nw',
			  -border	=> -2,
			  -pady 	=> -10, 
			  -padx 	=> 10, 
			  -widget 	=> \$hl,
			  -column 	=> $c,
			  -command	=> [\&refresh, $obj, $c],
			);

			$obj->Advertise(sprintf("HB_%d", $c) => $obj->{header}->{$c});   #Buttons PART.

			# create Images (Text)
			my $img = $obj->{header}->{$c}->Compound;
			$obj->{header}->{$c}->configure(-image => $img);
			$img->Line;
			$img->Text(-text => $field); 
			if(defined $sortcolumn and $sortcolumn == $c and ($obj->direction eq 'ASC' or $obj->direction eq 'DESC')) {
				$img->Space(-width => 4);
				$img->Bitmap(-bitmap => ($obj->direction eq 'ASC' ? $BITMAPUP : $BITMAPDOWN));
				$img->Space(-width => 10);
			} else {
				$img->Space(-width => 24);
			}

			$hl->headerCreate($c, 
				-itemtype => 'window',
				-widget	  => $obj->{header}->{$c}, 
			);

		} else {
			$hl->headerCreate($c,	-text => $field);
		}
		$hl->columnWidth($c, $obj->{columnWidths}->[$c]) 
			if(defined $obj->{columnWidths}->[$c]);
	}

	$hl->columnWidth(0, 0)
		unless($obj->{display_id});

#printf("SortCol: %s, Type: %s, Direction: %s\n", 
#	(defined $sortcolumn ? $sortcolumn : 'undef'), 
#	(defined $sortcolumn ? $obj->type($sortcolumn) : 'undef'), 
#	(defined $sortcolumn ? $obj->direction : 'undef')
#	); 
	
	# Rows ...
	$hl->delete('all');
	my $type = $obj->type($sortcolumn);
	if(defined $sortcolumn and $type eq 'TXT' and $obj->direction eq 'ASC') { 
		foreach my $zeile (sort { $a->[$sortcolumn] cmp $b->[$sortcolumn] } @$data) {
			$obj->draw_row($hl, $zeile, $sortcolumn);
		}
	} elsif(defined $sortcolumn and $type eq 'TXT' and $obj->direction eq 'DESC') {
		foreach my $zeile (sort { $b->[$sortcolumn] cmp $a->[$sortcolumn] } @$data) {
			$obj->draw_row($hl, $zeile, $sortcolumn);
		}
	} elsif(defined $sortcolumn and $type eq 'INT' and $obj->direction eq 'ASC') {
		foreach my $zeile (sort { $a->[$sortcolumn] <=> $b->[$sortcolumn] } @$data) {
			$obj->draw_row($hl, $zeile, $sortcolumn);
		}
	} elsif(defined $sortcolumn and $type eq 'INT' and $obj->direction eq 'DESC') {
		foreach my $zeile (sort { $b->[$sortcolumn] <=> $a->[$sortcolumn] } @$data) {
			$obj->draw_row($hl, $zeile, $sortcolumn);
		}
	} else {
		foreach my $zeile (@$data) {
			$obj->draw_row($hl, $zeile);
		}
	}
}

# ------------------------------------------
sub draw_row {
# ------------------------------------------
	my ($obj, $hl, $zeile, $sortcolumn) = @_;
	$hl->add($zeile->[0]);
	my $c = -1;
	foreach my $column (@$zeile) {
		$column = ' ' unless($column);
		$column =~ s/(\r|\n)//sig;
		$c++;
		$hl->itemCreate( $zeile->[0], $c, 
			-text => $column, 
		);
		$hl->itemConfigure($zeile->[0], $c,
			-style => $obj->{srtColumnStyle},
			) if(defined $sortcolumn and defined $obj->{srtColumnStyle} and $sortcolumn == $c);
	}
}

# ------------------------------------------
sub sortcol {
# ------------------------------------------
	my $obj = shift or croak("No object");
	$obj->{sortcol} = shift || $obj->{sortcol};
	$obj->refresh($obj->{sortcol});
}


# ------------------------------------------
sub toogle_direction {
# ------------------------------------------
	my $obj = shift or croak("No object");
	my $sortcolumn = shift;
	return $obj->direction('ASC') if(defined $sortcolumn and defined $obj->{sortcol} and $obj->{sortcol} != $sortcolumn);
	return $obj->direction('ASC') if($obj->direction() eq 'NONE');
	return $obj->direction('DESC') if($obj->direction() eq 'ASC');
	return $obj->direction('NONE') if($obj->direction() eq 'DESC');
}


# ------------------------------------------
sub direction {
# ------------------------------------------
	my $obj = shift or croak("No object");
	$obj->{direction} = shift || return $obj->{direction};
}

# ------------------------------------------
sub type {
# ------------------------------------------
	my $obj = shift or croak("No object");
	my $snr = shift or return;
	my $data = $obj->{data} || return;
	my $type = 'INT';	
	foreach (@$data){
		$_->[$snr] = ' ' unless(defined $_->[$snr]);
		$type = 'TXT' if(defined $_->[$snr] and $_->[$snr] =~ /[^0-9]+/);		
	}
	return $type;
}


# ------------------------------------------
sub getSql {
# ------------------------------------------
	my $obj = shift or croak("No object");
	my $sql = shift or return $obj->error('No Sql');
	my $dbh = $obj->{dbh};

	my $sth = $dbh->prepare($sql) or warn("$DBI::errstr - $sql");
	$sth->execute or warn("$DBI::errstr - $sql");
	$obj->{fields} = $sth->{'NAME'};
	return $sth->fetchall_arrayref;
}


# ------------------------------------------
sub debug {
# ------------------------------------------
	my $obj = shift;
	my $msg = shift || return;
	return unless $obj->{debug};
	printf("\nInfo: %s\n", $msg); 
} 

# ------------------------------------------
sub error {
# ------------------------------------------
	my $obj = shift;
	my $msg = shift;
	$obj->bell;
	unless($msg) {
		my $err = $obj->{error};
		$obj->{error} = '';
		return $err;
	}
	$obj->{error} = sprintf($msg, @_);
	return undef;
} 


1;



=head1 ADVERTISED WIDGETS


=head2 'table' => HList-Widget


This is a normal HList widget. I.e.:

	$dbitable->Subwidget('table')->configure(
		-command = sub{ printf "This is id: %s\n", $_[0] },
	};


=head2 'HB_<column number>' => Button-Widget

This is a (Resize)Button widget. This displays a Compound image with text and image.

=head1 AUTHOR

xpix@netzwert.ag

Copyright (C) 2003 , Frank (xpix) Herrmann. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

Tk::DBI::*, Tk::ResizeButton, Tk::HList


__END__
