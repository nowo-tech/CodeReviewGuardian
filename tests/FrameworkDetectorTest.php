<?php

declare(strict_types=1);

namespace NowoTech\CodeReviewGuardian\Tests;

use NowoTech\CodeReviewGuardian\FrameworkDetector;
use PHPUnit\Framework\TestCase;

/**
 * Test suite for FrameworkDetector class.
 *
 * @author Héctor Franco Aceituno <hectorfranco@nowo.tech>
 *
 * @see    https://github.com/HecFranco
 */
final class FrameworkDetectorTest extends TestCase
{
    public function testDetectSymfony(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-symfony.json';
        $this->createComposerJson($composerJsonPath, ['symfony/framework-bundle' => '^6.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_SYMFONY, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectLaravel(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-laravel.json';
        $this->createComposerJson($composerJsonPath, ['laravel/framework' => '^10.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_LARAVEL, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectYii(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-yii.json';
        $this->createComposerJson($composerJsonPath, ['yiisoft/yii2' => '^2.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_YII, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectGeneric(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-generic.json';
        $this->createComposerJson($composerJsonPath, ['some/package' => '^1.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_GENERIC, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectNonExistentFile(): void
    {
        $framework = FrameworkDetector::detect('/non/existent/path/composer.json');

        $this->assertEquals(FrameworkDetector::FRAMEWORK_GENERIC, $framework);
    }

    public function testGetConfigDirectory(): void
    {
        $this->assertEquals('symfony', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_SYMFONY));
        $this->assertEquals('laravel', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_LARAVEL));
        $this->assertEquals('generic', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_GENERIC));
    }

    /**
     * Create a temporary composer.json file for testing.
     *
     * @param string        $path    File path
     * @param array<string> $require Required packages
     */
    private function createComposerJson(string $path, array $require): void
    {
        $dir = dirname($path);
        if (!is_dir($dir)) {
            mkdir($dir, 0777, true);
        }

        $composerJson = [
            'name' => 'test/package',
            'require' => $require,
        ];

        file_put_contents($path, json_encode($composerJson, JSON_PRETTY_PRINT));
    }
}

