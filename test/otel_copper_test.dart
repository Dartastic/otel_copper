// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_copper/otel_copper.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_copper-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('opportunities.update records value + stage + status', () async {
    await tracedCopper<String>(
      operation: 'opportunities.update',
      invoke: () async => const CopperCallResult(
        value: 'ok',
        result: CopperResult(
          entityKind: 'opportunity',
          opportunityStatus: 'Open',
          pipelineStageId: 12,
          monetaryValueMinor: 2500000,
          currency: 'USD',
          rateLimitRemaining: 88,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('copper opportunities.update')!);
    expect(a['copper.entity.kind'], 'opportunity');
    expect(a['copper.opportunity.status'], 'Open');
    expect(a['copper.pipeline_stage.id'], 12);
    expect(a['copper.opportunity.value.minor'], 2500000);
    expect(a['copper.rate_limit.remaining'], 88);
  });

  test('activities.create with gmail sync', () async {
    await tracedCopper<String>(
      operation: 'activities.create',
      invoke: () async => const CopperCallResult(
        value: 'ok',
        result: CopperResult(entityKind: 'activity', gmailSynced: true),
      ),
    );
    final a = attrsOf(spans.findSpanByName('copper activities.create')!);
    expect(a['copper.activity.gmail_synced'], true);
  });

  test('suppression skips spans', () async {
    await runWithoutCopperInstrumentationAsync(() async {
      await tracedCopper<String>(
        operation: 'people.search',
        invoke: () async => const CopperCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('copper '), isEmpty);
  });
}
