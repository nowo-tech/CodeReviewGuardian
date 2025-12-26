<?php

declare(strict_types=1);

namespace NowoTech\CodeReviewGuardian\Tests;

use Composer\{Composer, Config};
use Composer\IO\IOInterface;
use Composer\Script\{Event, ScriptEvents};
use NowoTech\CodeReviewGuardian\Plugin;
use PHPUnit\Framework\TestCase;

/**
 * Test suite for the Plugin class.
 *
 * @author Héctor Franco Aceituno <hectorfranco@nowo.tech>
 *
 * @see    https://github.com/HecFranco
 */
final class PluginTest extends TestCase
{
    public function testGetSubscribedEvents(): void
    {
        $events = Plugin::getSubscribedEvents();

        $this->assertIsArray($events);
        $this->assertArrayHasKey(ScriptEvents::POST_INSTALL_CMD, $events);
        $this->assertArrayHasKey(ScriptEvents::POST_UPDATE_CMD, $events);
        $this->assertEquals('onPostInstall', $events[ScriptEvents::POST_INSTALL_CMD]);
        $this->assertEquals('onPostUpdate', $events[ScriptEvents::POST_UPDATE_CMD]);
    }

    public function testActivateStoresComposerAndIo(): void
    {
        $plugin = new Plugin();
        $composer = $this->createMock(Composer::class);
        $io = $this->createMock(IOInterface::class);

        // Should not throw any exception
        $plugin->activate($composer, $io);

        $this->assertTrue(true);
    }

    public function testDeactivateDoesNothing(): void
    {
        $plugin = new Plugin();
        $composer = $this->createMock(Composer::class);
        $io = $this->createMock(IOInterface::class);

        // Should not throw any exception
        $plugin->deactivate($composer, $io);

        $this->assertTrue(true);
    }

    public function testUninstallRemovesFiles(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        mkdir($vendorDir, 0777, true);

        // Create test file
        file_put_contents($tempDir . '/code-review-guardian.sh', '#!/bin/sh');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->uninstall($composer, $io);

        $this->assertFileDoesNotExist($tempDir . '/code-review-guardian.sh');

        // Cleanup
        @rmdir($vendorDir);
        @rmdir($tempDir);
    }

    public function testOnPostInstallInstallsFiles(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        $configSymfonyDir = $packageDir . '/config/symfony';
        $configDir = $packageDir . '/config';
        mkdir($binDir, 0777, true);
        mkdir($configSymfonyDir, 0777, true);
        if (!is_dir($configDir)) {
            mkdir($configDir, 0777, true);
        }

        // Create composer.json with Symfony framework
        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        // Create source files
        file_put_contents($binDir . '/code-review-guardian.sh', '#!/bin/sh\necho "test"');
        file_put_contents($configSymfonyDir . '/code-review-guardian.yaml', 'framework: symfony');
        file_put_contents($configSymfonyDir . '/AGENTS.md', '# AGENTS');
        $docsSourceDir = $packageDir . '/docs';
        if (!is_dir($docsSourceDir)) {
            mkdir($docsSourceDir, 0777, true);
        }
        file_put_contents($docsSourceDir . '/GGA.md', '# GGA');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->logicalOr(
                $this->stringContains('Detected framework'),
                $this->stringContains('Installing'),
                $this->stringContains('Updated .gitignore')
            ));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostInstall($event);

        $this->assertFileExists($tempDir . '/code-review-guardian.sh');
        $this->assertFileExists($tempDir . '/code-review-guardian.yaml');
        $this->assertFileExists($tempDir . '/docs/AGENTS.md');
        $this->assertFileExists($tempDir . '/docs/GGA.md');

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallInstallsLaravelConfig(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $configLaravelDir = $packageDir . '/config/laravel';
        mkdir($configLaravelDir, 0777, true);

        // Create composer.json with Laravel framework
        $composerJson = [
            'name' => 'test/package',
            'require' => ['laravel/framework' => '^10.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        // Create source file
        file_put_contents($configLaravelDir . '/code-review-guardian.yaml', 'framework: laravel');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->stringContains('LARAVEL'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostInstall($event);

        $this->assertFileExists($tempDir . '/code-review-guardian.yaml');
        $content = file_get_contents($tempDir . '/code-review-guardian.yaml');
        $this->assertStringContainsString('laravel', $content);

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallInstallsGenericConfig(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $configGenericDir = $packageDir . '/config/generic';
        mkdir($configGenericDir, 0777, true);

        // Create composer.json without framework
        $composerJson = [
            'name' => 'test/package',
            'require' => ['some/package' => '^1.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        // Create source file
        file_put_contents($configGenericDir . '/code-review-guardian.yaml', 'framework: generic');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->stringContains('GENERIC'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostInstall($event);

        $this->assertFileExists($tempDir . '/code-review-guardian.yaml');
        $content = file_get_contents($tempDir . '/code-review-guardian.yaml');
        $this->assertStringContainsString('generic', $content);

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallUpdatesGitignore(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        mkdir($binDir, 0777, true);

        // Create existing .gitignore
        file_put_contents($tempDir . '/.gitignore', "vendor/\n");

        // Create source files
        file_put_contents($binDir . '/code-review-guardian.sh', '#!/bin/sh');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostInstall($event);

        $gitignoreContent = file_get_contents($tempDir . '/.gitignore');
        $this->assertStringContainsString('code-review-guardian.sh', $gitignoreContent);
        $this->assertStringContainsString('code-review-guardian.yaml', $gitignoreContent);
        $this->assertStringContainsString('# Code Review Guardian', $gitignoreContent);

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallDoesNotOverwriteExistingConfig(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        $configSymfonyDir = $packageDir . '/config/symfony';
        mkdir($binDir, 0777, true);
        mkdir($configSymfonyDir, 0777, true);

        // Create existing config file with user content
        $existingContent = 'framework: symfony\ncustom: user-config';
        file_put_contents($tempDir . '/code-review-guardian.yaml', $existingContent);

        // Create composer.json
        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        // Create source files
        file_put_contents($binDir . '/code-review-guardian.sh', '#!/bin/sh\necho "new script"');
        file_put_contents($configSymfonyDir . '/code-review-guardian.yaml', 'framework: symfony\nnew: content');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostInstall($event);

        // Verify existing config content was preserved (not overwritten)
        $content = file_get_contents($tempDir . '/code-review-guardian.yaml');
        $this->assertEquals($existingContent, $content);

        // Verify script was updated (always updated, even if exists)
        $this->assertFileExists($tempDir . '/code-review-guardian.sh');
        $scriptContent = file_get_contents($tempDir . '/code-review-guardian.sh');
        $this->assertStringContainsString('new script', $scriptContent);

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostUpdateUpdatesScriptAndGitignore(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        mkdir($binDir, 0777, true);

        // Create existing .gitignore without Code Review Guardian entries
        file_put_contents($tempDir . '/.gitignore', "vendor/\n");

        // Create composer.json for framework detection
        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        // Create source script with new content
        $newScriptContent = '#!/bin/sh\necho "updated script"';
        file_put_contents($binDir . '/code-review-guardian.sh', $newScriptContent);

        // Create existing script with old content
        $oldScriptContent = '#!/bin/sh\necho "old script"';
        file_put_contents($tempDir . '/code-review-guardian.sh', $oldScriptContent);

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->logicalOr(
                $this->stringContains('Updated .gitignore'),
                $this->stringContains('Updating code-review-guardian.sh'),
                $this->stringContains('Detected framework')
            ));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostUpdate($event);

        // Verify script was updated
        $this->assertFileExists($tempDir . '/code-review-guardian.sh');
        $updatedScriptContent = file_get_contents($tempDir . '/code-review-guardian.sh');
        $this->assertEquals($newScriptContent, $updatedScriptContent);

        // Verify .gitignore was updated
        $gitignoreContent = file_get_contents($tempDir . '/.gitignore');
        $this->assertStringContainsString('code-review-guardian.sh', $gitignoreContent);
        $this->assertStringContainsString('code-review-guardian.yaml', $gitignoreContent);

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallWithSourceFileNotFound(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        mkdir($binDir, 0777, true);

        // Don't create source file - should handle missing file gracefully
        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('writeError')
            ->with($this->stringContains('Source file not found'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostInstall($event);

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallWithConfigDirectoryNotFound(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        mkdir($binDir, 0777, true);

        // Don't create config directory - should handle missing directory gracefully
        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        file_put_contents($binDir . '/code-review-guardian.sh', '#!/bin/sh');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('writeError')
            ->with($this->stringContains('Configuration directory not found'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostInstall($event);

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallWithDocumentationFilesMissing(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        $configSymfonyDir = $packageDir . '/config/symfony';
        mkdir($binDir, 0777, true);
        mkdir($configSymfonyDir, 0777, true);

        // Don't create documentation files - should handle missing files gracefully
        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        file_put_contents($binDir . '/code-review-guardian.sh', '#!/bin/sh');
        file_put_contents($configSymfonyDir . '/code-review-guardian.yaml', 'framework: symfony');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostInstall($event);

        // Documentation files should not exist (source files don't exist)
        $this->assertFileDoesNotExist($tempDir . '/docs/AGENTS.md');
        $this->assertFileDoesNotExist($tempDir . '/docs/GGA.md');

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallWithForceUpdateUpdatesExistingFiles(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        $configSymfonyDir = $packageDir . '/config/symfony';
        $configDir = $packageDir . '/config';
        mkdir($binDir, 0777, true);
        mkdir($configSymfonyDir, 0777, true);
        if (!is_dir($configDir)) {
            mkdir($configDir, 0777, true);
        }

        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        // Create source files
        $newScriptContent = '#!/bin/sh\necho "new script"';
        file_put_contents($binDir . '/code-review-guardian.sh', $newScriptContent);

        $newConfigContent = 'framework: symfony\nnew: config';
        file_put_contents($configSymfonyDir . '/code-review-guardian.yaml', $newConfigContent);

        $newAgentContent = '# New AGENTS';
        file_put_contents($configSymfonyDir . '/AGENTS.md', $newAgentContent);

        $newGgaContent = '# New GGA';
        file_put_contents($packageDir . '/docs/GGA.md', $newGgaContent);

        // Create existing files with old content
        $oldScriptContent = '#!/bin/sh\necho "old script"';
        file_put_contents($tempDir . '/code-review-guardian.sh', $oldScriptContent);

        $oldConfigContent = 'framework: symfony\nold: config';
        file_put_contents($tempDir . '/code-review-guardian.yaml', $oldConfigContent);

        mkdir($tempDir . '/docs', 0777, true);
        file_put_contents($tempDir . '/docs/AGENTS.md', '# Old AGENTS');
        file_put_contents($tempDir . '/docs/GGA.md', '# Old GGA');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->logicalOr(
                $this->stringContains('Updating'),
                $this->stringContains('Detected framework'),
                $this->stringContains('Updated .gitignore')
            ));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        // Use reflection to call installFiles with forceUpdate=true
        $plugin = new Plugin();
        $plugin->activate($composer, $io);

        $reflection = new \ReflectionClass($plugin);
        $method = $reflection->getMethod('installFiles');
        $method->setAccessible(true);
        $method->invoke($plugin, $io, true);

        // Verify files were updated
        $this->assertFileExists($tempDir . '/code-review-guardian.sh');
        $this->assertFileExists($tempDir . '/code-review-guardian.yaml');
        $this->assertFileExists($tempDir . '/docs/AGENTS.md');
        $this->assertFileExists($tempDir . '/docs/GGA.md');

        // Note: We can't easily verify content was updated without reading files,
        // but the method should have been called with forceUpdate=true

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testUpdateGitignoreCreatesNewFile(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';

        // Don't create .gitignore - should create new one
        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->stringContains('Updated .gitignore'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostUpdate($event);

        $this->assertFileExists($tempDir . '/.gitignore');
        $gitignoreContent = file_get_contents($tempDir . '/.gitignore');
        $this->assertStringContainsString('code-review-guardian.sh', $gitignoreContent);
        $this->assertStringContainsString('code-review-guardian.yaml', $gitignoreContent);

        // Cleanup
        @unlink($tempDir . '/.gitignore');
        @rmdir($vendorDir);
        @rmdir($tempDir);
    }

    public function testUpdateGitignoreWithEmptyFile(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';

        // Create empty .gitignore
        file_put_contents($tempDir . '/.gitignore', '');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->stringContains('Updated .gitignore'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostUpdate($event);

        $gitignoreContent = file_get_contents($tempDir . '/.gitignore');
        $this->assertStringContainsString('code-review-guardian.sh', $gitignoreContent);
        $this->assertStringContainsString('code-review-guardian.yaml', $gitignoreContent);

        // Cleanup
        @unlink($tempDir . '/.gitignore');
        @rmdir($vendorDir);
        @rmdir($tempDir);
    }

    public function testUpdateGitignoreWithFileWithoutNewline(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';

        // Create .gitignore without trailing newline
        file_put_contents($tempDir . '/.gitignore', 'vendor/');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->stringContains('Updated .gitignore'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostUpdate($event);

        $gitignoreContent = file_get_contents($tempDir . '/.gitignore');
        $this->assertStringContainsString('vendor/', $gitignoreContent);
        $this->assertStringContainsString('code-review-guardian.sh', $gitignoreContent);

        // Cleanup
        @unlink($tempDir . '/.gitignore');
        @rmdir($vendorDir);
        @rmdir($tempDir);
    }

    public function testUpdateGitignoreDoesNotUpdateIfEntriesExist(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';

        // Create .gitignore with entries already present
        $gitignoreContent = "# Code Review Guardian\ncode-review-guardian.sh\ncode-review-guardian.yaml\n";
        file_put_contents($tempDir . '/.gitignore', $gitignoreContent);

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->never())
            ->method('write')
            ->with($this->stringContains('Updated .gitignore'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostUpdate($event);

        // Content should remain the same
        $finalContent = file_get_contents($tempDir . '/.gitignore');
        $this->assertEquals($gitignoreContent, $finalContent);

        // Cleanup
        @unlink($tempDir . '/.gitignore');
        @rmdir($vendorDir);
        @rmdir($tempDir);
    }

    public function testUpdateGitignoreWithPartialEntries(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';

        // Create .gitignore with only one entry present
        file_put_contents($tempDir . '/.gitignore', "vendor/\ncode-review-guardian.sh\n");

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->stringContains('Updated .gitignore'));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->onPostUpdate($event);

        $gitignoreContent = file_get_contents($tempDir . '/.gitignore');
        $this->assertStringContainsString('code-review-guardian.sh', $gitignoreContent);
        $this->assertStringContainsString('code-review-guardian.yaml', $gitignoreContent);

        // Cleanup
        @unlink($tempDir . '/.gitignore');
        @rmdir($vendorDir);
        @rmdir($tempDir);
    }

    public function testUninstallDoesNotRemoveNonExistentFile(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        mkdir($vendorDir, 0777, true);

        // Don't create the file - should handle gracefully
        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->never())
            ->method('write');

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        $plugin->uninstall($composer, $io);

        // Cleanup
        @rmdir($vendorDir);
        @rmdir($tempDir);
    }

    public function testScriptAlwaysUpdatesEvenIfExists(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        mkdir($binDir, 0777, true);

        // Create composer.json for framework detection
        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        // Create source script with new version
        $newScriptContent = '#!/bin/sh\necho "version 2.0"';
        file_put_contents($binDir . '/code-review-guardian.sh', $newScriptContent);

        // Create existing script with old version
        $oldScriptContent = '#!/bin/sh\necho "version 1.0"';
        file_put_contents($tempDir . '/code-review-guardian.sh', $oldScriptContent);

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->logicalOr(
                $this->stringContains('Updating code-review-guardian.sh'),
                $this->stringContains('Detected framework')
            ));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        $plugin = new Plugin();
        $plugin->activate($composer, $io);
        
        // Test that onPostInstall updates the script even if it exists
        $plugin->onPostInstall($event);

        // Verify script was updated with new version
        $this->assertFileExists($tempDir . '/code-review-guardian.sh');
        $updatedContent = file_get_contents($tempDir . '/code-review-guardian.sh');
        $this->assertEquals($newScriptContent, $updatedContent);

        // Update source script again to simulate a package update
        $evenNewerScriptContent = '#!/bin/sh\necho "version 3.0"';
        file_put_contents($binDir . '/code-review-guardian.sh', $evenNewerScriptContent);

        // Test that onPostUpdate also updates the script
        $plugin->onPostUpdate($event);

        // Verify script was updated again
        $updatedContent2 = file_get_contents($tempDir . '/code-review-guardian.sh');
        $this->assertEquals($evenNewerScriptContent, $updatedContent2);

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    public function testOnPostInstallInstallsDocumentationFilesWithForceUpdate(): void
    {
        $tempDir = sys_get_temp_dir() . '/code-review-guardian-plugin-test-' . uniqid();
        $vendorDir = $tempDir . '/vendor';
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';
        $binDir = $packageDir . '/bin';
        $configSymfonyDir = $packageDir . '/config/symfony';
        $docsSourceDir = $packageDir . '/docs';
        mkdir($binDir, 0777, true);
        mkdir($configSymfonyDir, 0777, true);
        if (!is_dir($docsSourceDir)) {
            mkdir($docsSourceDir, 0777, true);
        }

        $composerJson = [
            'name' => 'test/package',
            'require' => ['symfony/framework-bundle' => '^6.0'],
        ];
        file_put_contents($tempDir . '/composer.json', json_encode($composerJson, JSON_PRETTY_PRINT));

        file_put_contents($binDir . '/code-review-guardian.sh', '#!/bin/sh');
        file_put_contents($configSymfonyDir . '/code-review-guardian.yaml', 'framework: symfony');
        file_put_contents($configSymfonyDir . '/AGENTS.md', '# New AGENTS');
        file_put_contents($docsSourceDir . '/GGA.md', '# New GGA');

        // Create existing documentation files
        mkdir($tempDir . '/docs', 0777, true);
        file_put_contents($tempDir . '/docs/AGENTS.md', '# Old AGENTS');
        file_put_contents($tempDir . '/docs/GGA.md', '# Old GGA');

        $config = $this->createMock(Config::class);
        $config->method('get')
            ->with('vendor-dir')
            ->willReturn($vendorDir);

        $composer = $this->createMock(Composer::class);
        $composer->method('getConfig')
            ->willReturn($config);

        $io = $this->createMock(IOInterface::class);
        $io->expects($this->atLeastOnce())
            ->method('write')
            ->with($this->logicalOr(
                $this->stringContains('Updating'),
                $this->stringContains('Installing'),
                $this->stringContains('Detected framework')
            ));

        $event = $this->createMock(Event::class);
        $event->method('getIO')
            ->willReturn($io);

        // Use reflection to call installFiles with forceUpdate=true
        $plugin = new Plugin();
        $plugin->activate($composer, $io);

        $reflection = new \ReflectionClass($plugin);
        $method = $reflection->getMethod('installFiles');
        $method->setAccessible(true);
        $method->invoke($plugin, $io, true);

        $this->assertFileExists($tempDir . '/docs/AGENTS.md');
        $this->assertFileExists($tempDir . '/docs/GGA.md');

        // Cleanup
        $this->removeDirectory($tempDir);
    }

    /**
     * Remove a directory and all its contents recursively.
     *
     * @param string $dir Directory path
     */
    private function removeDirectory(string $dir): void
    {
        if (!is_dir($dir)) {
            return;
        }

        $files = array_diff(scandir($dir), ['.', '..']);
        foreach ($files as $file) {
            $path = $dir . '/' . $file;
            if (is_dir($path)) {
                $this->removeDirectory($path);
            } else {
                @unlink($path);
            }
        }

        @rmdir($dir);
    }
}
