<?php

declare(strict_types=1);

namespace NowoTech\CodeReviewGuardian\Tests\Integration;

use NowoTech\CodeReviewGuardian\Plugin;
use PHPUnit\Framework\TestCase;

/**
 * Smoke tests for the Composer plugin in an integration-style suite.
 */
final class ComposerPluginIntegrationTest extends TestCase
{
    public function testPluginClassIsDiscoverable(): void
    {
        $this->assertTrue(class_exists(Plugin::class));
    }
}
