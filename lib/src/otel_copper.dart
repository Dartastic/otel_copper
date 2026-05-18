// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_copper_suppression.dart';

const _tracerName = 'dartastic_otel_libs_copper';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class CopperResult {
  const CopperResult({
    this.itemCount,
    this.entityKind,
    this.opportunityStatus,
    this.pipelineStageId,
    this.monetaryValueMinor,
    this.currency,
    this.gmailSynced,
    this.rateLimitRemaining,
    this.requestId,
    this.statusCode,
  });

  /// Items in collection.
  final int? itemCount;

  /// `person` / `company` / `opportunity` / `lead` / `activity` /
  /// `project` / `task`.
  final String? entityKind;

  /// `Open` / `Won` / `Lost` / `Abandoned` for opportunities.
  final String? opportunityStatus;

  /// `pipeline_stage_id`.
  final int? pipelineStageId;

  /// `monetary_value` in minor units.
  final int? monetaryValueMinor;

  /// ISO 4217.
  final String? currency;

  /// Whether the activity has been synced to Gmail (Copper's
  /// signature integration).
  final bool? gmailSynced;

  /// `X-RateLimit-Remaining`.
  final int? rateLimitRemaining;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class CopperCallResult<T> {
  const CopperCallResult({required this.value, this.result});
  final T value;
  final CopperResult? result;
}

/// Wraps a Copper API call in a CLIENT span. [operation] is one of
/// `people.search`, `people.create`, `people.update`, `people.get`,
/// `companies.search`, `companies.create`, `opportunities.search`,
/// `opportunities.create`, `opportunities.update`, `leads.search`,
/// `activities.list`, `activities.create`, `projects.list`,
/// `tasks.list`, `webhooks.create`.
Future<T> tracedCopper<T>({
  required String operation,
  required Future<CopperCallResult<T>> Function() invoke,
}) async {
  if (copperInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'copper',
    'rpc.method': operation,
    'copper.operation': operation,
  };

  final span = _tracer().startSpan(
    'copper $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'copper.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.entityKind != null) {
        extras.add(OTel.attributeString(
          'copper.entity.kind',
          r.result!.entityKind!,
        ));
      }
      if (r.result!.opportunityStatus != null) {
        extras.add(OTel.attributeString(
          'copper.opportunity.status',
          r.result!.opportunityStatus!,
        ));
      }
      if (r.result!.pipelineStageId != null) {
        extras.add(OTel.attributeInt(
          'copper.pipeline_stage.id',
          r.result!.pipelineStageId!,
        ));
      }
      if (r.result!.monetaryValueMinor != null) {
        extras.add(OTel.attributeInt(
          'copper.opportunity.value.minor',
          r.result!.monetaryValueMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'copper.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.gmailSynced != null) {
        extras.add(OTel.attributeBool(
          'copper.activity.gmail_synced',
          r.result!.gmailSynced!,
        ));
      }
      if (r.result!.rateLimitRemaining != null) {
        extras.add(OTel.attributeInt(
          'copper.rate_limit.remaining',
          r.result!.rateLimitRemaining!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'copper.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Copper HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
