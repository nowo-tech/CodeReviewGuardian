<?php

declare(strict_types=1);

namespace NowoTech\CodeReviewGuardian;

/**
 * Detects the framework used in a PHP project.
 *
 * @author Héctor Franco Aceituno <hectorfranco@nowo.tech>
 *
 * @see    https://github.com/HecFranco
 */
class FrameworkDetector
{
    public const FRAMEWORK_SYMFONY = 'symfony';
    public const FRAMEWORK_LARAVEL = 'laravel';
    public const FRAMEWORK_YII = 'yii';
    public const FRAMEWORK_CAKEPHP = 'cakephp';
    public const FRAMEWORK_LAMINAS = 'laminas';
    public const FRAMEWORK_CODEIGNITER = 'codeigniter';
    public const FRAMEWORK_SLIM = 'slim';
    public const FRAMEWORK_GENERIC = 'generic';

    /**
     * Framework packages mapping.
     *
     * @var array<string, string>
     */
    private const FRAMEWORK_PACKAGES = [
        'symfony/framework-bundle' => self::FRAMEWORK_SYMFONY,
        'laravel/framework' => self::FRAMEWORK_LARAVEL,
        'yiisoft/yii2' => self::FRAMEWORK_YII,
        'yiisoft/yii' => self::FRAMEWORK_YII,
        'cakephp/cakephp' => self::FRAMEWORK_CAKEPHP,
        'laminas/laminas-mvc' => self::FRAMEWORK_LAMINAS,
        'codeigniter4/framework' => self::FRAMEWORK_CODEIGNITER,
        'slim/slim' => self::FRAMEWORK_SLIM,
    ];

    /**
     * Detect framework from composer.json file.
     *
     * @param string $composerJsonPath Path to composer.json
     *
     * @return string Detected framework name
     */
    public static function detect(string $composerJsonPath): string
    {
        if (!file_exists($composerJsonPath)) {
            return self::FRAMEWORK_GENERIC;
        }

        $composerJson = json_decode(file_get_contents($composerJsonPath), true);

        if (!is_array($composerJson)) {
            return self::FRAMEWORK_GENERIC;
        }

        $require = array_merge(
            $composerJson['require'] ?? [],
            $composerJson['require-dev'] ?? []
        );

        foreach (self::FRAMEWORK_PACKAGES as $package => $framework) {
            if (isset($require[$package])) {
                return $framework;
            }
        }

        return self::FRAMEWORK_GENERIC;
    }

    /**
     * Get configuration directory for a framework.
     *
     * @param string $framework Framework name
     *
     * @return string Configuration directory
     */
    public static function getConfigDirectory(string $framework): string
    {
        $frameworkDirs = [
            self::FRAMEWORK_SYMFONY => 'symfony',
            self::FRAMEWORK_LARAVEL => 'laravel',
            self::FRAMEWORK_YII => 'generic',
            self::FRAMEWORK_CAKEPHP => 'generic',
            self::FRAMEWORK_LAMINAS => 'generic',
            self::FRAMEWORK_CODEIGNITER => 'generic',
            self::FRAMEWORK_SLIM => 'generic',
            self::FRAMEWORK_GENERIC => 'generic',
        ];

        return $frameworkDirs[$framework] ?? 'generic';
    }
}

