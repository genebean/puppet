require 'opentelemetry-instrumentation-net_http'
require 'opentelemetry-propagator-b3'
require 'opentelemetry-sdk'
require 'opentelemetry/exporter/jaeger'
require 'opentelemetry/resource/detectors'
require 'puppet/version'

module Puppet::Util::OpenTelemetry
  # TODO: this should check a Puppet configuration setting to determine if traces should be emmitted. 
  if tracing_enabled
    # TODO: this should be pulled from a Puppet configuration setting instead of what's here
    tracing_jaeger_host = ENV['PUPPET_TRACING_JAEGER_HOST'] || 'http://localhost:14268/api/traces'

    Puppet.debug("Exporting of traces will be done over HTTP in binary Thrift format to #{tracing_jaeger_host}")
    span_processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      exporter: OpenTelemetry::Exporter::Jaeger::CollectorExporter.new(endpoint: tracing_jaeger_host)
    )
  else
    Puppet.debug("Exporting of traces has been disabled so the span processor has been se to a 'NoopSpanExporter'")
    span_processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      exporter: OpenTelemetry::SDK::Trace::Export::NoopSpanExporter.new
    )
  end

  b3_text_map_injectors = [OpenTelemetry::Propagator::B3::Single.text_map_injector]
  b3_text_map_extractors = [OpenTelemetry::Propagator::B3::Single.text_map_extractor, OpenTelemetry::Propagator::B3::Multi.text_map_extractor]
  b3_http_extractors = [OpenTelemetry::Propagator::B3::Single.rack_extractor, OpenTelemetry::Propagator::B3::Multi.rack_extractor]
  
  w3c_text_map_injectors = [OpenTelemetry::Trace::Propagation::TraceContext.text_map_injector, OpenTelemetry::Baggage::Propagation.text_map_injector]
  w3c_text_map_extractors = [OpenTelemetry::Trace::Propagation::TraceContext.text_map_extractor, OpenTelemetry::Baggage::Propagation.text_map_extractor]
  w3c_http_extractors =  [OpenTelemetry::Trace::Propagation::TraceContext.rack_extractor, OpenTelemetry::Baggage::Propagation.rack_extractor]

  OpenTelemetry::SDK.configure do |c|
    c.resource = OpenTelemetry::Resource::Detectors::AutoDetector.detect
    c.service_name = 'puppet' # TODO: can we check to see if this is plain puppet or puppetserver or bolt or .... ?
    c.service_version = Puppet.version

    c.use 'OpenTelemetry::Instrumentation::Net::HTTP'

    c.http_extractors = w3c_http_extractors + b3_http_extractors
    c.http_injectors = w3c_text_map_injectors + b3_text_map_injectors

    c.text_map_extractors = w3c_text_map_extractors + b3_text_map_extractors
    c.text_map_injectors = w3c_text_map_injectors + b3_text_map_injectors

    c.add_span_processor(span_processor)
  end
end
