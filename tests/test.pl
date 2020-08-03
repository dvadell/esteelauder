#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use LWP::Simple;
use JSON;

my $ua = LWP::UserAgent->new;
my $api_base = "http://app:3000/api";

sub api {
    my $opt = shift;
    my $req = HTTP::Request->new( $opt->{"method"}, "$api_base/transactions" );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $opt->{"json"} );
    my $res = $ua->request( $req );
    return $res;
}

# Create a valid credit (POST /transactions)
my $json = '{"type":"credit", "amount": 10}';
my $res = api({ json => $json, method => 'POST' });
is($res->code, 201, "Create a valid credit (POST /transactions)");

# Check if a debit really rests
# * List the transactions (GET /transactions)
$res = $ua->get("$api_base/transactions");
is($res->code, 200, "List the transactions (GET /transactions)");
# * Calculate the balance
my $balance = calculate_balance(decode_json($res->content));
# * Create a valid debit (POST /transactions)
$json = '{"type":"debit", "amount": 5}';
$res = api({ json => $json, method => 'POST' });
is($res->code, 201, "Create a valid debit (POST /transactions)");
# * Check if the balance is now 5 less
$res = $ua->get("$api_base/transactions");
is($res->code, 200, "List the transactions (GET /transactions)");
my $new_balance = calculate_balance(decode_json($res->content));
is($balance - 5, $new_balance, "Debits works");

# List the transactions (GET /transactions)
$res = $ua->get("$api_base/transactions");
is($res->code, 200, "List the transactions (GET /transactions)");

# Create an invalid transaction (POST /transactions)
$json = '{"type":"nonexistent", "amount": 10, "text": "invalid"}';
$res = api({ json => $json, method => 'POST' });
is($res->code, 400, "Create an invalid transaction (POST /transactions)");

# Create a valid transaction that would lead to a negative amount (POST /transactions)
$json = '{"type":"debit", "amount": 1000}';
$res = api({ json => $json, method => 'POST' });
is($res->code, 400, "Create a valid transaction that would lead to a negative amount (POST /transactions)");

# List the transactions (GET /transactions)
$res = $ua->get("$api_base/transactions");
is($res->code, 200, "List the transactions (GET /transactions)");

# Get one non-existent transaction (GET /transactions/:id)
$res = $ua->get("$api_base/transactions/12345");
is($res->code, 400, "Get one non-existent transaction (GET /transactions/:id)");

# Get one existent transaction (GET /transactions/:id)
$res = $ua->get("$api_base/transactions");
my ($id) = $res->content =~ /"id":"(.*?)"/;
$res = $ua->get("$api_base/transactions/$id");
is($res->code, 200, "Get one existent transaction (GET /transactions/:id)");
my $transaction = decode_json($res->content);
isa_ok($transaction, 'HASH', 'Returns a JSON hash');

done_testing();

sub calculate_balance {
    my $transactions = shift;
    my $total = 0;
    foreach my $t (@$transactions) {
       my $sign = 1;
       if ($t->{"type"} eq "debit") {
           $sign = -1;
       }
       $total = $total + $sign * $t->{"amount"};
    }
    return $total;
}
