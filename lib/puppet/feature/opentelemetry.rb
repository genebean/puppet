require 'puppet/util/feature'

Puppet.features.add(:opentelemetry, :libs => [
  'opentelemetry-instrumentation-net_http'
  'opentelemetry-propagator-b3'
  'opentelemetry-sdk'
  'opentelemetry/exporter/jaeger'
  'opentelemetry/resource/detectors'
])
