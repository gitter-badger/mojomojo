package # hide from PAUSE
    MojoMojoTestSchema;

use strict;
use warnings;
use MojoMojo::Schema;
use YAML;

my $attrs          = {add_drop_table => 1, no_comments => 1};


=head1 NAME

MojoMojoTestSchema - Library to be used by DBIx::Class test scripts.

=head1 SYNOPSIS

  use lib qw(t/lib);
  use MojoMojoTestSchema;
  use Test::More;

  my $schema = MojoMojoTestSchema->init_schema();

=head1 DESCRIPTION

This module provides the basic utilities to write tests against
MojoMojo::Schema. Shamelessly stolen from DBICTest in the DBIx::Class test suite.

=head1 METHODS

=head2 init_schema

  my $schema = MojoMojoTestSchema->init_schema(
    no_deploy=>1,
    no_populate=>1,
  );

This method removes the test SQLite database in t/var/mojomojo.db
and then creates a new, empty database.

This method will call deploy_schema() by default, unless the
no_deploy flag is set.

Also, by default, this method will call populate_schema() by
default, unless the no_deploy or no_populate flags are set.

=cut

sub init_schema {
    my $self = shift;
    my %args = @_;

    my $db_dir = 't/var';
    my $db_file = "$db_dir/mojomojo.db";

    unlink($db_file) if -e $db_file;
    mkdir($db_dir) unless -d $db_dir;

    my $dsn = $ENV{"MOJOMOJO_TEST_SCHEMA_DSN"} || "dbi:SQLite:${db_file}";
    my $dbuser = $ENV{"MOJOMOJO_TEST_SCHEMA_DBUSER"} || '';
    my $dbpass = $ENV{"MOJOMOJO_TEST_SCHEMA_DBPASS"} || '';

    my $schema = MojoMojo::Schema->compose_connection('MojoMojoTestSchema' => $dsn, $dbuser, $dbpass);
    if ( !$args{no_deploy} ) {
        __PACKAGE__->deploy_schema( $schema );
        __PACKAGE__->populate_schema( $schema ) if( !$args{no_populate} );
    }
    my $config = {
	name => 'MojoMojo Test Suite',
	'Model::DBIC' => {
	    connect_info => [ $dsn ], 
	}
    };
    YAML::DumpFile('t/var/mojomojo.yml',$config);
    

    return $schema;
}

=head2 deploy_schema

  MojoMojoTestSchema->deploy_schema( $schema );

This method does one of two things to the schema.  It can either call
the experimental $schema->deploy() if the DBICTEST_SQLT_DEPLOY environment
variable is set, otherwise the default is to read in the db/sqlite/mojomojo.sql
file and execute the SQL within. Either way you end up with a fresh set
of tables for testing.

=cut

sub deploy_schema {
    my $self = shift;
    my $schema = shift;

    return $schema->deploy();
}

=head2 populate_schema

  DBICTest->populate_schema( $schema );

After you deploy your schema you can use this method to populate
the tables with test data.

=cut

sub populate_schema {
    my $self = shift;
    my $db = shift;

    $db->storage->dbh->do("PRAGMA synchronous = OFF");

        $db->storage->ensure_connected;
        $db->deploy( $attrs );

        my @people = $db->populate('Person', [
    					  [ qw/ active views photo login name email pass timezone born gender occupation industry interests movies music / ],
    					  [ 1,0,0,'AnonymousCoward','Anonymous Coward','','','',0,'','','','','','' ],
    					  [ 1,0,0,'admin','Enoch Root','','admin','',0,'','','','','','' ],
    					 ]);

        $db->populate('Preference', [
    				 [ qw/ prefkey prefvalue / ],
    				 [ 'name','MojoMojo' ],
    				 [ 'admins','admin' ],
    				]);

        $db->populate('PageVersion', [
    				  [ qw/page version parent parent_version name name_orig depth
    				       content_version_first content_version_last creator status created
    				       release_date remove_date comments/ ],
    				  [ 1,1,undef,undef,'/','/',0,1,1, $people[1]->id,'',0,'','','' ],
    				 ]);

        $db->populate('Content', [
    			      [ qw/ page version creator created body status release_date remove_date type abstract comments 
    				    precompiled / ],
    			      [ 1,1, $people[1]->id, 0,'h1. Welcome to MojoMojo!

    This is your front page. To start administrating your wiki, please log in with
    username admin/password admin. At that point you will be able to set up your
    configuration. If you want to play around a little with the wiki, just create
    a NewPage or edit this one through the edit link at the bottom.

    h2. Need some assistance?

    Check out our [[Help]] section.','released','','','','','','' ],
    			      [ 2,1,1,0,'h1. Help Index.

    * Editing Pages
    * Formatter Syntax.
    * Using Tags
    * Attachments & Photos','released','','','','','','' ],
    			     ]);

        $db->populate('Page', [
    			   [ qw/ id version parent name name_orig depth lft rgt content_version / ],
    			   [ 1,1,undef,'/','/',0,1,4,1 ],
    			   [ 2,1,1,'help','Help',1,2,3,1 ],
    			  ]);
}

1;

