<?php

echo "\nPackage (PHP) for Code Review.\n";

$path = $argc > 1 ? $argv[1] : null;

if ( is_null( $path ) || ! is_dir( $path ) ) {

	echo "\n\tUSAGE: php ./pkg-for-code-review.php [path-to-code]\n";
	die(1);

}

echo "\nPackaging for code review ...\n";

if ( $zip_file = Package_For_Code_Review::go( $path ) ) {

	echo "\n\nPackaging complete in \"{$zip_file}.\"";

} else {

	echo "\n\nPackaging Failed.";

}

echo "\n\n";


/**
 * Class Package_For_Code_Review
 */
class Package_For_Code_Review {

	const ZIP_FILE = 'for-code-review.zip';


	static function go( $path ) {

		do {

			$path = realpath( $path );

			$zip = new ZipArchive();

			if ( true !== $zip->open( $zip_file = __DIR__ . '/' . self::ZIP_FILE, ZIPARCHIVE::OVERWRITE ) ) {
				break;
			}

			$files = new RecursiveIteratorIterator(
				new RecursiveDirectoryIterator( $path ),
				RecursiveIteratorIterator::SELF_FIRST
			);

			foreach( $files as $file ) {

				/**
				 * @var SplFileObject $file
				 */

				if ( 'php' !== $file->getExtension() ) {
					continue;
				}

				$local_path = self::local_filename( $file->getPathname(), $path );

				echo "\nAdding {$local_path} ...";

				$zip->addFile( $file->getPathname(), $local_path );
			}

		} while ( false );

		$zip->close();

		return is_file( $zip_file ) ? self::ZIP_FILE : false;

	}

	static function local_filename( $filepath, $abspath ) {

		return preg_replace( '#^' . preg_quote( $abspath ) . '(.+)#', '$1', $filepath );

	}
}
