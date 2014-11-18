# --
# Kernel/System/TicketOverview/Hooks/MarkIncidentsWithClosedProblems.pm - mark tickets that have closed parents in ticket overview
# Copyright (C) 2013 - 2014 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketOverview::Hooks::MarkIncidentsWithClosedProblems;

use strict;
use warnings;

our $VERSION = 0.04;

our @ObjectDependencies = qw(
    Kernel::System::LinkObject
    Kernel::System::Log
    Kernel::System::TicketUtilsMIWCP
);

=head1 NAME

Kernel::System::TicketOverview::Hooks::MarkIncidentsWithClosedProblems - mark tickets in ticket overview that have closed parents

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item Run()

Returns a color when the ticket belongs to the Junk-Queue

    my $JunkColor = $JunkObject->Run(
        TicketID => 123,
    );

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $UtilsObject  = $Kernel::OM->Get('Kernel::System::TicketUtilsMIWCP');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');

    # check needed stuff
    for my $Needed (qw(TicketID Type)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my @IncidentTypes = @{ $ConfigObject->Get( 'MarkIncidentsWithClosedProblems::IncidentType' ) || [] };
    my $IsType;

    for my $Type ( @IncidentTypes ) {
        my $HasWildcard = $Type =~ m{\*};

        if ( $HasWildcard ) {
            $Type =~ s{\*}{.*}g;
            $IsType = 1 if $Param{Type} =~ m{\A$Type}ms;
        }
        else {
            $IsType = 1 if $Param{Type} eq $Type;
        }
    }

    return if !$IsType;

    my %Opts;
    if ( !$ConfigObject->Get('MarkIncidentsWithClosedProblems::AllRelationships') ) {
        $Opts{Type} = 'ParentChild';
    }

    my $LinkList = $LinkObject->LinkList(
        Object  => 'Ticket',
        Key     => $Param{TicketID},
        Object2 => 'Ticket',
        UserID  => 1,
        State   => 'Valid',
        %Opts,
    );

    return if !$LinkList;

    my $LinkedTickets = $LinkList->{Ticket};

    return if !$LinkedTickets;

    my %TicketIDs;

    TYPE:
    for my $Type ( keys %{$LinkedTickets} ) {

        my $RelatedByType = $LinkedTickets->{$Type};

        next TYPE if !$RelatedByType;

        DIRECTION:
        for my $Direction ( qw/Source Target/ ) {

            my $PossibleIncidents = $RelatedByType->{$Direction};

            next DIRECTION if !$PossibleIncidents;

            my @FoundTicketIDs = keys %{ $PossibleIncidents };
            @TicketIDs{@FoundTicketIDs} = (1) x @FoundTicketIDs;
        }
    }

    my @TicketIDs         = keys %TicketIDs;
    my $HasClosedProblems = $UtilsObject->CheckClosedProblems( TicketIDs => \@TicketIDs );

    return if !$HasClosedProblems;

    my $Color = $ConfigObject->Get('MarkIncidentsWithClosedProblems::Color') || '';
    return $Color;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

