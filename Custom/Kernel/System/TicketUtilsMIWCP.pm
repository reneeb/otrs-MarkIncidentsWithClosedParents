# --
# Kernel/System/TicketMIWCP.pm - all ticket functions
# Copyright (C) 2013 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketUtilsMIWCP;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (qw(ConfigObject LogObject TimeObject DBObject MainObject EncodeObject)) {
        if ( $Param{$Needed} ) {
            $Self->{$Needed} = $Param{$Needed};
        }
        else {
            die "Got no $Needed!";
        }
    }

    return $Self;
}

sub CheckClosedProblems {
    my ($Self, %Param) = @_;

    for my $Needed ( qw/TicketIDs/ ) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $Binds = join ', ', ('?') x @{ $Param{TicketIDs} };
    my $SQL = 'SELECT t.id, tt.name, tst.name FROM ticket t 
                   INNER JOIN ticket_type tt ON t.type_id = tt.id
                   INNER JOIN ticket_state ts ON ts.id = t.ticket_state_id
                   INNER JOIN ticket_state_type tst ON ts.type_id = tst.id
                   WHERE t.id IN( ' . $Binds . ') AND tt.name LIKE "Problem%" AND tst.name = "closed"';

    return if !$Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Bind  =>[  map{ \$_ }@{ $Param{TicketIDs} } ],
        Limit => 1,
    );

    my $HasClosedProblems;

    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $HasClosedProblems++;
    }

    return $HasClosedProblems;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
