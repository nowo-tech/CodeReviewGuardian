<?php

declare(strict_types=1);

namespace NowoTech\CodeReviewGuardian;

use Composer\Composer;
use Composer\EventDispatcher\EventSubscriberInterface;
use Composer\IO\IOInterface;
use Composer\Plugin\PluginInterface;
use Composer\Script\{Event, ScriptEvents};

/**
 * Composer plugin that installs code review guardian configuration files.
 * Works with any PHP project (Symfony, Laravel, Yii, CodeIgniter, etc.)
 * and any Git provider (GitHub, GitLab, Bitbucket, etc.)
 *
 * @author Héctor Franco Aceituno <hectorfranco@nowo.tech>
 *
 * @see    https://github.com/HecFranco
 */
class Plugin implements PluginInterface, EventSubscriberInterface
{
    /** @var Composer The Composer instance */
    private Composer $composer;

    /** @var IOInterface The IO interface */
    private IOInterface $io;

    /**
     * Get the octal permission mode compatible with the current PHP version.
     *
     * @return int The permission mode
     */
    private function getChmodMode(): int
    {
        return octdec('755');
    }

    /**
     * Activate the plugin.
     *
     * @param Composer    $composer The Composer instance
     * @param IOInterface $io       The IO interface
     */
    public function activate(Composer $composer, IOInterface $io): void
    {
        $this->composer = $composer;
        $this->io = $io;
    }

    /**
     * Deactivate the plugin.
     *
     * @param Composer    $composer The Composer instance
     * @param IOInterface $io       The IO interface
     */
    public function deactivate(Composer $composer, IOInterface $io): void
    {
    }

    /**
     * Uninstall the plugin.
     *
     * @param Composer    $composer The Composer instance
     * @param IOInterface $io       The IO interface
     */
    public function uninstall(Composer $composer, IOInterface $io): void
    {
        $this->removeFiles($io);
    }

    /**
     * Get the subscribed events.
     *
     * @return array<string, string> The subscribed events
     */
    public static function getSubscribedEvents(): array
    {
        return [
            ScriptEvents::POST_INSTALL_CMD => 'onPostInstall',
            ScriptEvents::POST_UPDATE_CMD => 'onPostUpdate',
        ];
    }

    /**
     * Handle post-install command event.
     *
     * @param Event $event The script event
     */
    public function onPostInstall(Event $event): void
    {
        // Script file (.sh) will always be updated, config files only if they don't exist
        $this->installFiles($event->getIO(), false);
    }

    /**
     * Handle post-update command event.
     *
     * @param Event $event The script event
     */
    public function onPostUpdate(Event $event): void
    {
        // Script file (.sh) will always be updated, config files only if they don't exist
        $this->installFiles($event->getIO(), false);
    }

    /**
     * Install files to the project root.
     *
     * @param IOInterface $io          The IO interface
     * @param bool        $forceUpdate Force update even if files exist
     */
    private function installFiles(IOInterface $io, bool $forceUpdate = false): void
    {
        $vendorDir = $this->composer->getConfig()->get('vendor-dir');
        $projectDir = dirname((string) $vendorDir);
        $packageDir = $vendorDir . '/nowo-tech/code-review-guardian';

        // If package is not in vendor (development mode), use current directory
        if (!is_dir($packageDir)) {
            $packageDir = __DIR__ . '/..';
        }

        // Detect framework
        $composerJsonPath = $projectDir . '/composer.json';
        $framework = FrameworkDetector::detect($composerJsonPath);
        $configDir = FrameworkDetector::getConfigDirectory($framework);

        $io->write(sprintf('<info>Detected framework: %s</info>', strtoupper($framework)));

        // Install code review script
        // Note: The .sh script is ALWAYS updated to ensure users have the latest version
        // This is different from config files which are only installed if they don't exist
        $files = [
            'bin/code-review-guardian.sh' => 'code-review-guardian.sh',
        ];

        foreach ($files as $source => $dest) {
            $sourcePath = $packageDir . '/' . $source;
            $destPath = $projectDir . '/' . $dest;

            if (!file_exists($sourcePath)) {
                $io->writeError(sprintf('<warning>Source file not found: %s</warning>', $sourcePath));
                continue;
            }

            // Always update the script file, regardless of $forceUpdate flag
            // This ensures users always have the latest version with bug fixes and new features
            if (file_exists($destPath)) {
                $io->write(sprintf('<info>Updating %s</info>', $dest));
            } else {
                $io->write(sprintf('<info>Installing %s</info>', $dest));
            }

            copy($sourcePath, $destPath);
            chmod($destPath, $this->getChmodMode());
        }

        // Install framework-specific configuration files
        $this->installFrameworkConfig($packageDir, $projectDir, $configDir, $io, $forceUpdate);

        // Install documentation files (AGENTS.md, GGA.md)
        $this->installDocumentationFiles($packageDir, $projectDir, $io, $forceUpdate);

        // Update .gitignore to exclude installed files
        $this->updateGitignore($projectDir, $io);
    }

    /**
     * Install framework-specific configuration files.
     *
     * @param string      $packageDir  Package directory
     * @param string      $projectDir  Project directory
     * @param string      $configDir   Configuration directory name
     * @param IOInterface $io          The IO interface
     * @param bool        $forceUpdate Force update even if files exist
     */
    private function installFrameworkConfig(
        string $packageDir,
        string $projectDir,
        string $configDir,
        IOInterface $io,
        bool $forceUpdate
    ): void {
        $configSourceDir = $packageDir . '/config/' . $configDir;
        $configDestDir = $projectDir;

        if (!is_dir($configSourceDir)) {
            $io->writeError(sprintf('<warning>Configuration directory not found: %s</warning>', $configSourceDir));

            return;
        }

        // List of configuration files to install
        $configFiles = [
            'code-review-guardian.yaml' => 'code-review-guardian.yaml',
        ];

        foreach ($configFiles as $source => $dest) {
            $sourcePath = $configSourceDir . '/' . $source;
            $destPath = $configDestDir . '/' . $dest;

            if (!file_exists($sourcePath)) {
                continue;
            }

            // Only install if file doesn't exist (don't overwrite user's config)
            if (file_exists($destPath) && !$forceUpdate) {
                continue;
            }

            if (file_exists($destPath)) {
                $io->write(sprintf('<info>Updating %s</info>', $dest));
            } else {
                $io->write(sprintf('<info>Installing %s</info>', $dest));
            }

            copy($sourcePath, $destPath);
        }
    }

    /**
     * Install documentation files (AGENTS.md, GGA.md) to project.
     *
     * @param string      $packageDir  Package directory
     * @param string      $projectDir  Project directory
     * @param IOInterface $io          The IO interface
     * @param bool        $forceUpdate Force update even if files exist
     */
    private function installDocumentationFiles(
        string $packageDir,
        string $projectDir,
        IOInterface $io,
        bool $forceUpdate
    ): void {
        $docsDestDir = $projectDir . '/docs';

        // Create docs directory if it doesn't exist
        if (!is_dir($docsDestDir)) {
            mkdir($docsDestDir, 0755, true);
        }

        // Detect framework for framework-specific AGENTS.md
        $composerJsonPath = $projectDir . '/composer.json';
        $framework = FrameworkDetector::detect($composerJsonPath);
        $configDir = FrameworkDetector::getConfigDirectory($framework);

        // AGENTS.md is framework-specific (from config/{framework}/AGENTS.md)
        // GGA.md is common (from docs/GGA.md)
        $agentSourcePath = $packageDir . '/config/' . $configDir . '/AGENTS.md';
        $ggaSourcePath = $packageDir . '/docs/GGA.md';

        // List of documentation files to install (source => dest)
        $docFiles = [];

        // Framework-specific AGENTS.md
        if (file_exists($agentSourcePath)) {
            $docFiles[$agentSourcePath] = 'AGENTS.md';
        }

        // Common GGA.md
        if (file_exists($ggaSourcePath)) {
            $docFiles[$ggaSourcePath] = 'GGA.md';
        }

        foreach ($docFiles as $sourcePath => $dest) {
            $destPath = $docsDestDir . '/' . $dest;

            if (!file_exists($sourcePath)) {
                continue;
            }

            // Only install if file doesn't exist (don't overwrite user's documentation)
            if (file_exists($destPath) && !$forceUpdate) {
                continue;
            }

            if (file_exists($destPath)) {
                $io->write(sprintf('<info>Updating %s</info>', $dest));
            } else {
                $io->write(sprintf('<info>Installing %s</info>', $dest));
            }

            copy($sourcePath, $destPath);
        }
    }

    /**
     * Update .gitignore on update (without regenerating files).
     *
     * @param IOInterface $io The IO interface
     */
    private function updateGitignoreOnUpdate(IOInterface $io): void
    {
        $vendorDir = $this->composer->getConfig()->get('vendor-dir');
        $projectDir = dirname((string) $vendorDir);
        $this->updateGitignore($projectDir, $io);
    }

    /**
     * Update .gitignore to exclude Code Review Guardian files.
     *
     * @param string      $projectDir The project root directory
     * @param IOInterface $io         The IO interface
     */
    private function updateGitignore(string $projectDir, IOInterface $io): void
    {
        $gitignorePath = $projectDir . '/.gitignore';
        $entriesToAdd = [
            'code-review-guardian.sh',
            'code-review-guardian.yaml',
        ];

        $content = '';
        $lines = [];

        if (file_exists($gitignorePath)) {
            $content = file_get_contents($gitignorePath);
            $lines = explode("\n", $content);
        }

        $updated = false;
        $existingEntries = array_map('trim', $lines);

        foreach ($entriesToAdd as $entry) {
            if (!in_array($entry, $existingEntries, true)) {
                // Add a comment if this is the first entry and file exists
                if (!$updated && file_exists($gitignorePath) && !empty($content)) {
                    $trimmedContent = trim($content);
                    if ($trimmedContent !== '' && substr($trimmedContent, -1) !== "\n") {
                        $lines[] = '';
                    }
                }
                // Add comment header if this is the first Code Review Guardian entry
                if (!$updated && !in_array('# Code Review Guardian', $existingEntries, true)) {
                    $lines[] = '# Code Review Guardian';
                }
                $lines[] = $entry;
                $updated = true;
            }
        }

        if ($updated) {
            file_put_contents($gitignorePath, implode("\n", $lines) . "\n");
            $io->write('<info>Updated .gitignore to exclude Code Review Guardian files</info>');
        }
    }

    /**
     * Remove files from the project root.
     *
     * @param IOInterface $io The IO interface
     */
    private function removeFiles(IOInterface $io): void
    {
        $vendorDir = $this->composer->getConfig()->get('vendor-dir');
        $projectDir = dirname((string) $vendorDir);

        $io->write('<info>Removing Code Review Guardian files...</info>');

        // Files to remove from project root
        $files = [
            'code-review-guardian.sh',
            'code-review-guardian.yaml',
        ];

        $removedCount = 0;
        foreach ($files as $file) {
            $path = $projectDir . '/' . $file;

            if (file_exists($path)) {
                $io->write(sprintf('  <comment>-</comment> Removing <info>%s</info>', $file), false);
                unlink($path);
                $io->write(' <info>✓</info>');
                $removedCount++;
            }
        }

        // Remove documentation files
        $docsDir = $projectDir . '/docs';
        $docFiles = [
            'AGENTS.md',
        ];

        foreach ($docFiles as $file) {
            $path = $docsDir . '/' . $file;

            if (file_exists($path)) {
                $io->write(sprintf('  <comment>-</comment> Removing <info>docs/%s</info>', $file), false);
                unlink($path);
                $io->write(' <info>✓</info>');
                $removedCount++;
            }
        }

        // Remove .gitignore entries
        $io->write('<info>Cleaning up .gitignore...</info>');
        $this->removeGitignoreEntries($projectDir, $io);

        if ($removedCount > 0) {
            $io->write(sprintf('<info>✓ Removed %d file(s) successfully</info>', $removedCount));
        } else {
            $io->write('<info>No files to remove (already cleaned up)</info>');
        }
    }

    /**
     * Remove Code Review Guardian entries from .gitignore.
     *
     * @param string      $projectDir The project root directory
     * @param IOInterface $io         The IO interface
     */
    private function removeGitignoreEntries(string $projectDir, IOInterface $io): void
    {
        $gitignorePath = $projectDir . '/.gitignore';

        if (!file_exists($gitignorePath)) {
            return;
        }

        $content = file_get_contents($gitignorePath);
        $lines = explode("\n", $content);

        $entriesToRemove = [
            'code-review-guardian.sh',
            'code-review-guardian.yaml',
        ];

        $updated = false;
        $newLines = [];
        $skipSection = false;

        foreach ($lines as $line) {
            $trimmedLine = trim($line);

            // Check if this is the Code Review Guardian section comment
            if ($trimmedLine === '# Code Review Guardian') {
                $skipSection = true;
                continue;
            }

            // Check if we should skip this line (it's an entry to remove)
            if ($skipSection && in_array($trimmedLine, $entriesToRemove, true)) {
                $updated = true;
                continue;
            }

            // If we encounter a non-empty line that's not in our entries, stop skipping
            if ($skipSection && $trimmedLine !== '' && !in_array($trimmedLine, $entriesToRemove, true)) {
                $skipSection = false;
            }

            // Also check for entries not in the section
            if (!$skipSection && in_array($trimmedLine, $entriesToRemove, true)) {
                $updated = true;
                continue;
            }

            $newLines[] = $line;
        }

        // Remove trailing empty lines after the section if section was removed
        while (!empty($newLines) && trim(end($newLines)) === '') {
            array_pop($newLines);
        }

        if ($updated) {
            $io->write('  <comment>-</comment> Removing entries from <info>.gitignore</info>', false);
            file_put_contents($gitignorePath, implode("\n", $newLines) . "\n");
            $io->write(' <info>✓</info>');
        }
    }
}
