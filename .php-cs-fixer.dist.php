<?php

declare(strict_types=1);

use PhpCsFixer\Config;
use PhpCsFixer\Finder;

return (new Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PSR12' => true,
        '@Symfony' => true,
        '@Symfony:risky' => true,
        'declare_strict_types' => true,
        'fully_qualified_strict_types' => [
            // Convert \Foo\Bar to use Foo\Bar; + Bar (instanceof, new, types, ::class, etc.).
            'import_symbols' => true,
        ],
        'ordered_imports' => [
            'imports_order' => ['class', 'function', 'const'],
            'sort_algorithm' => 'alpha',
        ],
        'single_import_per_statement' => true,
        'no_unused_imports' => true,
        'single_line_after_imports' => true,
    ])
    ->setFinder(
        (new Finder())
            ->in(__DIR__ . '/src')
            ->in(__DIR__ . '/tests')
            ->exclude(['vendor', 'var', 'coverage', '.phpunit.cache'])
            ->files()
    );
