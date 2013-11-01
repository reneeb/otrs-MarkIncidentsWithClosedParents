# --
# Kernel/System/TicketOverview/Hooks/MarkIncidentsWithClosedProblems.pm - mark tickets based on the queue in ticket overview
# Copyright (C) 2013 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketOverview::Hooks::MarkIncidentsWithClosedProblems;

use strict;
use warnings;

use Kernel::System::LinkObject;
use Kernel::System::Ticket;
use Kernel::System::TicketUtilsMIWCP;

our $VERSION = 0.01;

=head1 NAME

Kernel::System::TicketOverview::Hooks::Junk - mark junk tickets in ticket overview

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::TicketOverview::Hooks::Junk;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $JunkObject = Kernel::System::TicketOverview::Hooks::Junk->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
        EncodeObject => $EncodeObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(DBObject ConfigObject MainObject LogObject EncodeObject TimeObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }
    
    # create needed objects
    $Self->{TicketObject} = Kernel::System::Ticket->new( %{$Self} );
    $Self->{UtilsObject}  = Kernel::System::TicketUtilsMIWCP->new( %{$Self} );
    $Self->{LinkObject}   = Kernel::System::LinkObject->new( %{$Self} );

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

    # check needed stuff
    for my $Needed (qw(TicketID Type)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    return if $Param{Type} !~ m{\AIncident}xms;

    my $LinkList = $Self->{LinkObject}->LinkList(
        Object  => 'Ticket',
        Key     => $Param{TicketID},
        Object2 => 'Ticket',
        Type    => 'ParentChild',
        UserID  => 1,
        State   => 'Valid',
    );

    return if !$LinkList;

    my $LinkedTickets = $LinkList->{Ticket};

    return if !$LinkedTickets;

    my $ParentChilds = $LinkedTickets->{ParentChild};

    return if !$ParentChilds;

    my $PossibleProblems = $ParentChilds->{Target};

    return if !$PossibleProblems;

    my @TicketIDs         = keys %{ $PossibleProblems };
    my $HasClosedProblems = $Self->{UtilsObject}->CheckClosedProblems( TicketIDs => \@TicketIDs );

    my $Color = $Self->{ConfigObject}->Get('MarkIncidentsWithClosedProblems::Color') || '';

    return $Color;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

