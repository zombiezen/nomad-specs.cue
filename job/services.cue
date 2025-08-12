// Copyright 2025 Roxy Light
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

package job

import (
	"strconv"
	"time"
)

// https://developer.hashicorp.com/nomad/docs/job-specification/check_restart
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/services.go#L135-L141
#CheckRestart: {
	// TODO(maybe): Nomad allows groups to pass partial fields and those will be merged with the job policy.
	// CUE lets us do this more cleanly, so I'd prefer to specify the whole object.

	Limit:          uint | *0
	Grace:          #Duration | *(1 * time.Second)
	IgnoreWarnings: bool | *false
}

// ServiceCheck represents a Nomad job-submitters view of a Consul service health check.
// https://developer.hashicorp.com/nomad/docs/job-specification/check
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/services.go#L200-L229
#ServiceCheck: {
	Name:           string
	Type:           "http" | "tcp" | "grpc" | "script"
	PortLabel?:     string
	Expose:         bool | *false
	AddressMode:    "alloc" | "driver" | *"host"
	Interval:       #Duration & >=(1 * time.Second)
	Timeout:        #Duration & >=(1 * time.Second)
	InitialStatus?: "passing" | "warning" | "critical"
	CheckRestart:   #CheckRestart | *null
	TaskName:       string
	OnUpdate:       *"require_healthy" | "ignore_warnings" | "ignore"

	if Type == "script" {
		Command: string
		Args: [...string]
	}

	if Type != "script" {
		SuccessBeforePassing:   int | *0
		FailuresBeforeCritical: int | *0
		FailuresBeforeWarning:  int | *0
	}

	if Type == "grpc" {
		GRPCService: string | *""
		GRPCUseTLS:  bool | *false

		if GRPCUseTLS {
			TLSServerName?: string
			TLSSkipVerify:  bool | *false
		}
	}

	if Type == "http" {
		Protocol: *"http" | "https"
		Header: {[string]: [...string]} | *null
		Method: string | *""
		Path:   string
		Body:   string | *""

		if Protocol == "https" {
			TLSServerName?: string
			TLSSkipVerify:  bool | *false
		}
	}
}

// Service represents a Nomad job-submitters view of a Consul or Nomad service.
// https://developer.hashicorp.com/nomad/docs/job-specification/service
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/services.go#L231-L260
#Service: {
	serviceName=Name: string
	Tags: [...string]
	CanaryTags: [...string]
	EnableTagOverride: bool | *false
	PortLabel?:        string
	AddressMode:       *"auto" | "alloc" | "driver" | "host"
	Checks: [...#ServiceCheck & {
		Name:     string | *"service: \(strconv.Quote(serviceName)) check"
		TaskName: serviceTaskName
	}]
	CheckRestart: #CheckRestart | *null
	Meta: {[string]: string}
	CanaryMeta: {[string]: string}
	TaggedAddresses: {[string]: string} | *null
	serviceTaskName=TaskName: string
	OnUpdate:                 *"require_healthy" | "ignore_warnings" | "ignore"

	Provider: *"consul" | "nomad"

	if Provider == "consul" {
		Cluster:  string | *"default"
		Weights:  #ServiceWeights
		Kind?:    string
		Identity: #WorkloadIdentity | *null
		// TODO(someday): Connect
	}

	if Provider != "consul" {
		Checks: [...#ServiceCheck & {
			// TODO(soon): Forbid InitialStatus.
			Type:                   "http" | "tcp"
			SuccessBeforePassing:   0
			FailuresBeforeCritical: 0
			FailuresBeforeWarning:  0
		}]
	}

	if AddressMode == "auto" {
		Address?: string
	}
}

_#ServiceWithDefaults: {
	X=in: {
		JobName:   string
		GroupName: string
	}

	out: #Service & {
		TaskName: _
		if TaskName == "" {
			Name: #Service.Name | *"\(X.JobName)-\(X.GroupName)"
		}
		if TaskName != "" {
			Name: #Service.Name | *"\(X.JobName)-\(X.GroupName)-\(TaskName)"
		}
	}
}

// ServiceWeights is the jobspec block which configures how a service instance
// is weighted in a DNS SRV request based on the service's health status.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/services.go#L341-L346
#ServiceWeights: {
	Passing: (int & >=1) | *1
	Warning: (int & >=1) | *1
}
