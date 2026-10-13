<?php

declare(strict_types=1);

namespace NowoTech\CodeReviewGuardian\Tests;

use PHPUnit\Framework\TestCase;
use Symfony\Component\Process\Process;

/**
 * Behaviour tests for the shell scripts shipped in bin/ (run through bash).
 *
 * @author Héctor Franco Aceituno <hectorfranco@nowo.tech>
 *
 * @see    https://github.com/HecFranco
 */
final class ShellScriptsTest extends TestCase
{
    private string $workDir;

    protected function setUp(): void
    {
        if (!is_executable('/bin/bash') && !is_executable('/usr/bin/bash')) {
            self::markTestSkipped('bash is required to run the shell script tests.');
        }

        $this->workDir = sys_get_temp_dir().'/crg-shell-test-'.uniqid();
        mkdir($this->workDir.'/tmp', 0777, true);
    }

    protected function tearDown(): void
    {
        if (isset($this->workDir)) {
            $this->removeDirectory($this->workDir);
        }
    }

    public function testLoadConfigAppliesDefaultsForMissingKeys(): void
    {
        file_put_contents($this->workDir.'/code-review-guardian.yaml', "gga:\n  enabled: true\nagents:\n  enabled: false\n");

        $result = $this->runBash(
            'load_config >/dev/null; printf "%s|%s|%s|%s|%s|%s|%s\n" '
            .'"$CONFIG_GGA_MAX_COMMENTS" "$CONFIG_GGA_PROVIDER" "$CONFIG_GGA_RULES_FILE" '
            .'"$CONFIG_AGENTS_MODEL" "$CONFIG_AGENTS_SUGGEST_FIXES" "$CONFIG_AGENTS_SEVERITY_THRESHOLD" "$CONFIG_COMMENTS_FORMAT"',
        );

        $this->assertSame(0, $result['exit'], $result['stderr']);
        $this->assertSame('50|codex|docs/AGENTS.md|gpt-4|true|medium|markdown', trim($result['stdout']));
    }

    public function testLoadConfigReadsConfiguredValues(): void
    {
        file_put_contents($this->workDir.'/code-review-guardian.yaml', <<<'YAML'
            gga:
              max_comments: 7 # inline comment
              provider: "claude"
            agents:
              enabled: true
              model: gpt-5
              behavior:
                suggest_fixes: false
                severity_threshold: high # only high
            comments:
              format: text
            YAML);

        $result = $this->runBash(
            'load_config >/dev/null; printf "%s|%s|%s|%s|%s|%s\n" '
            .'"$CONFIG_GGA_MAX_COMMENTS" "$CONFIG_GGA_PROVIDER" "$CONFIG_AGENTS_MODEL" '
            .'"$CONFIG_AGENTS_SUGGEST_FIXES" "$CONFIG_AGENTS_SEVERITY_THRESHOLD" "$CONFIG_COMMENTS_FORMAT"',
        );

        $this->assertSame(0, $result['exit'], $result['stderr']);
        $this->assertSame('7|claude|gpt-5|false|high|text', trim($result['stdout']));
    }

    public function testGetGitTokenPrintsOnlyTheTokenOnStdout(): void
    {
        file_put_contents($this->workDir.'/code-review-guardian.yaml', "git:\n  api_token_env: MY_TOKEN\n");
        file_put_contents($this->workDir.'/.env', "MY_TOKEN=secret-value\n");

        $result = $this->runBash('get_git_token');

        $this->assertSame(0, $result['exit'], $result['stderr']);
        $this->assertSame("secret-value\n", $result['stdout']);
    }

    public function testGetGitTokenSendsDiagnosticsToStderrWhenTokenIsMissing(): void
    {
        file_put_contents($this->workDir.'/code-review-guardian.yaml', "git:\n  api_token_env: MY_TOKEN\n");

        $result = $this->runBash('get_git_token');

        $this->assertSame(1, $result['exit']);
        $this->assertSame('', $result['stdout']);
        $this->assertStringContainsString('Git token not found: MY_TOKEN', $result['stderr']);
        $this->assertFileExists($this->workDir.'/.env');
    }

    public function testRunReviewUsesPrivateTemporaryFileAndCleansItUp(): void
    {
        file_put_contents($this->workDir.'/code-review-guardian.yaml', <<<'YAML'
            gga:
              enabled: true
              review_changed_files_only: false
            YAML);
        file_put_contents($this->workDir.'/a.php', "<?php\n");
        file_put_contents($this->workDir.'/b.txt', "text\n");

        $git = $this->runBash('git init -q . && git add a.php b.txt');
        $this->assertSame(0, $git['exit'], $git['stderr']);

        $result = $this->runBash('DRY_RUN=true; run_review');

        $this->assertSame(0, $result['exit'], $result['stderr']);
        $this->assertStringContainsString('Found 2 file(s) to review', $result['stdout']);
        $this->assertStringContainsString('  - a.php', $result['stdout']);
        $this->assertStringContainsString('  - b.txt', $result['stdout']);
        // The temporary file was created through mktemp under $TMPDIR and removed afterwards
        $this->assertSame([], array_values(array_diff((array) scandir($this->workDir.'/tmp'), ['.', '..'])));
    }

    /**
     * @return array{exit: int, stdout: string, stderr: string}
     */
    private function runBash(string $snippet): array
    {
        $binDir = \dirname(__DIR__, 2).'/bin';
        $script = \sprintf(
            '. %1$s/functions.sh; . %1$s/config.sh; . %1$s/review.sh; . %1$s/comments.sh; %2$s',
            escapeshellarg($binDir),
            $snippet,
        );

        $env = [
            'PATH' => (string) getenv('PATH'),
            'HOME' => $this->workDir,
            'TMPDIR' => $this->workDir.'/tmp',
        ];

        // symfony/process ships with composer/composer (a dependency of this plugin)
        $process = new Process(['bash', '-c', $script], $this->workDir, $env, null, 60);
        $process->run();

        return [
            'exit' => (int) $process->getExitCode(),
            'stdout' => $process->getOutput(),
            'stderr' => $process->getErrorOutput(),
        ];
    }

    private function removeDirectory(string $dir): void
    {
        if (!is_dir($dir) || is_link($dir)) {
            @unlink($dir);

            return;
        }

        foreach (array_diff((array) scandir($dir), ['.', '..']) as $file) {
            $this->removeDirectory($dir.'/'.$file);
        }

        @rmdir($dir);
    }
}
