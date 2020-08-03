#!/usr/bin/env perl
use strict;
use warnings;

package Transactions;
use Scalar::Util qw(looks_like_number);
use UUID::Tiny ':std';
use Time::HiRes qw(time);
use POSIX qw(strftime);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_transactions create_transaction get_transaction_by_id);


my @_transaction_list = ();
my $_transaction_list_lock = 0;

# Note: Mojolicious is single-threaded, IO-Loop based. It should never
#       happen that $_transaction_list_lock is not 0. But I was asked
#       for some form of concurrency control to data structures.
sub get_transactions {
    while ( $_transaction_list_lock != 0 ) {
        sleep 1;
    }
    return @_transaction_list;
};

# Return one transaction by Id
# Receives: the id
# Returns: the transaction or undefined.
sub get_transaction_by_id {
    my $id = shift;
    while ( $_transaction_list_lock != 0 ) {
        sleep 1;
    }
    foreach my $transaction (@_transaction_list) { 
        return $transaction if ( $transaction->{"id"} eq $id );
    }
    return;
};

# Create a transaction
# Receives: the parameteres from the HTTP POST.
#  * type: credit|debit
#  * amount: number
# Returns: true|false
sub create_transaction  {
    my $params = shift;

    # Check if we have all the fields
    if (! ($params->{"type"} eq "credit" || $params->{"type"} eq "debit")) {
        return ("ERROR", "invalid input");
    }
    if (! looks_like_number($params->{"amount"})) {
        return ("ERROR", "invalid input");
    }

    # Lock the data structure with a simple lock
    $_transaction_list_lock++;

    # Check if we'd be getting a negative amount (the "future balance").
    my $future_balance = _get_future_balance($params);

    if ($future_balance < 0) {
        # Unlock the data structure and return error
        $_transaction_list_lock--;
        return ("ERROR", "Refused transaction: can't allow negative balance amount");
    }

    # Add the transaction
    ## The date must be in this format: 2020-08-02T14:18:25.106Z
    ##                                  \=  %F  =/T\= %T =/
    my $now = time;
    my $milliseconds = sprintf ".%03d", ($now-int($now))*1000;
    my $effectiveDate = strftime("%FT%T", localtime($now)) . $milliseconds . "Z";
    
    my $uuid   = create_uuid_as_string();
    my $type   = $params->{"type"};
    my $amount = $params->{"amount"};
    push(@_transaction_list, {
        id            => $uuid,
        type          => $type,
        amount        => $amount,
        effectiveDate => $effectiveDate,
    });
    # Unlock the data structure
    $_transaction_list_lock--;

    # This sleep is just to show how Mojolicious is blocking.
    # sleep 100000;
    return ("OK", "ok");
};

# Get the would-be balance (the current balance + the one in the new transaction)
# Receives: $param (hash)
# Returns: the sum (scalar)
sub _get_future_balance {
    my $params = shift;
    my $balance = 0;

    # First get the balance
    foreach my $transaction (@_transaction_list) {
        my $amount = $transaction->{"amount"};
        if ($transaction->{"type"} eq "debit") {
            $amount = $amount * -1;
        }
        $balance = $balance + $amount;
    }

    # Then see if this is a debit or a credit and convert to signed.
    my $curr_amount = $params->{"amount"};
    if ($params->{"type"} eq "debit") {
        $curr_amount = $curr_amount * -1;
    }

    # Return the balance if the transaction would be made
    return $balance + $curr_amount;
}



1; 
