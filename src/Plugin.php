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
        $this->installFiles($event->getIO(), false);
    }

    /**
     * Handle post-update command event.
     *
     * @param Event $event The script event
     */
    public function onPostUpdate(Event $event): void
    {
        // Only update .gitignore on updates, don't regenerate files
        $this->updateGitignoreOnUpdate($event->getIO());
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

            // Only install if file doesn't exist (first installation)
            if (file_exists($destPath) && !$forceUpdate) {
                continue;
            }

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

        // Update .gitignore to exclude installed files
        $this->updateGitignore($projectDir, $io);
    }

    /**
     * Install framework-specific configuration files.
     *
     * @param string      $packageDir Package directory
     * @param string      $projectDir Project directory
     * @param string      $configDir  Configuration directory name
     * @param IOInterface $io         The IO interface
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
            '.code-review-guardian.yml' => '.code-review-guardian.yml',
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
            '.code-review-guardian.yml',
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

        $files = [
            'code-review-guardian.sh',
            // Note: We don't remove the config file as it may contain user configuration
        ];

        foreach ($files as $file) {
            $path = $projectDir . '/' . $file;

            if (file_exists($path)) {
                $io->write(sprintf('<info>Removing %s</info>', $file));
                unlink($path);
            }
        }
    }
}

