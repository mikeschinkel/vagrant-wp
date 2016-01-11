<?php
/**
 *  Provisions a website.
 *  Currently this looks for /vagrant/sites/{$domain}/provision/sql/*.sql files,
 *  creates a DB for every domain and
 */
$go = strtolower( filter_input( INPUT_GET, 'go', FILTER_SANITIZE_STRING ) );
$domain =  $_SERVER['HTTP_HOST'];

if ( 'yes' === $go && is_dir( $sql_path = "/vagrant/sites/{$domain}/provision/sql" ) ) {

	$db = new mysqli( 'localhost', 'root', 'vagrant', 'wplib' );

	if ( 0 < $db->connect_errno ) {

		echo "ERROR: {$db->connect_errno}";
		die;

	}

	$db_name = str_replace( '.', '_', preg_replace( '#^dev.(.*)$#', '$1', $domain ) );

	$result = $db->query( "SHOW DATABASES LIKE '{$db_name}';" );
	if ( 1 === $result->num_rows ) {
		echo "Database `{$db_name}` already exists.";
		die;
	}

	$db->query( "CREATE DATABASE IF NOT EXISTS {$db_name} CHARSET utf8mb4;" );
	$db->query( "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'vagrant' WITH GRANT OPTION;" );
	$db->query( "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'vagrant' WITH GRANT OPTION;" );

	$db->close();

	$db = new mysqli( 'localhost', 'root', 'vagrant', $db_name );

	foreach ( glob( "{$sql_path}/*.sql" ) as $sql_file ) {

		/*
		 * http://stackoverflow.com/a/11525265/102699
		 */
		$file_pointer = file( $sql_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES );
		$query = '';

		foreach( $file_pointer as $line ) {

		    if ( ! empty( $line ) && false === strpos($line, '--') ) {
		        $query .= rtrim( $line );
		        if ( ';' === substr( $query, -1 ) ) {

		            $db->query( $query );
		            $query = '';

		        }
		    }

		}

	}

	$db->close();

}
echo "Database `{$db_name}` created and data imported.";
