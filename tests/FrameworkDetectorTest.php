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

    public function testDetectYii2(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-yii2.json';
        $this->createComposerJson($composerJsonPath, ['yiisoft/yii2' => '^2.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_YII, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectYii3(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-yii3.json';
        $this->createComposerJson($composerJsonPath, ['yiisoft/yii' => '^3.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_YII, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectCakePHP(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-cakephp.json';
        $this->createComposerJson($composerJsonPath, ['cakephp/cakephp' => '^5.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_CAKEPHP, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectLaminas(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-laminas.json';
        $this->createComposerJson($composerJsonPath, ['laminas/laminas-mvc' => '^3.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_LAMINAS, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectCodeIgniter(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-codeigniter.json';
        $this->createComposerJson($composerJsonPath, ['codeigniter4/framework' => '^4.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_CODEIGNITER, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectSlim(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-slim.json';
        $this->createComposerJson($composerJsonPath, ['slim/slim' => '^4.0']);

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_SLIM, $framework);

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

    public function testDetectWithInvalidJson(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-invalid.json';
        $dir = dirname($composerJsonPath);
        if (!is_dir($dir)) {
            mkdir($dir, 0777, true);
        }

        file_put_contents($composerJsonPath, '{ invalid json }');

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_GENERIC, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectWithRequireDev(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-require-dev.json';
        $dir = dirname($composerJsonPath);
        if (!is_dir($dir)) {
            mkdir($dir, 0777, true);
        }

        $composerJson = [
            'name' => 'test/package',
            'require' => ['some/package' => '^1.0'],
            'require-dev' => ['symfony/framework-bundle' => '^6.0'],
        ];

        file_put_contents($composerJsonPath, json_encode($composerJson, JSON_PRETTY_PRINT));

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_SYMFONY, $framework);

        unlink($composerJsonPath);
    }

    public function testDetectWithEmptyComposerJson(): void
    {
        $composerJsonPath = __DIR__ . '/fixtures/composer-empty.json';
        $dir = dirname($composerJsonPath);
        if (!is_dir($dir)) {
            mkdir($dir, 0777, true);
        }

        file_put_contents($composerJsonPath, '{}');

        $framework = FrameworkDetector::detect($composerJsonPath);

        $this->assertEquals(FrameworkDetector::FRAMEWORK_GENERIC, $framework);

        unlink($composerJsonPath);
    }

    public function testGetConfigDirectoryForAllFrameworks(): void
    {
        $this->assertEquals('symfony', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_SYMFONY));
        $this->assertEquals('laravel', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_LARAVEL));
        $this->assertEquals('generic', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_YII));
        $this->assertEquals('generic', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_CAKEPHP));
        $this->assertEquals('generic', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_LAMINAS));
        $this->assertEquals('generic', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_CODEIGNITER));
        $this->assertEquals('generic', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_SLIM));
        $this->assertEquals('generic', FrameworkDetector::getConfigDirectory(FrameworkDetector::FRAMEWORK_GENERIC));
    }

    public function testGetConfigDirectoryWithUnknownFramework(): void
    {
        $this->assertEquals('generic', FrameworkDetector::getConfigDirectory('unknown-framework'));
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
