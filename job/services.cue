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
	Limit:          uint | *0
	Grace:          int64 | *(1 * time.Second)
	IgnoreWarnings: bool | *false
}

// ServiceCheck represents a Nomad job-submitters view of a Consul service health check.
// https://developer.hashicorp.com/nomad/docs/job-specification/check
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/services.go#L200-L229
#ServiceCheck: {
	Name:    string
	Type:    "http" | "tcp" | "grpc" | "script"
	Command: string | *""
	Args: [...string] | *null
	Path:          string | *""
	Protocol:      "http" | "https" | ""
	PortLabel:     string | *""
	Expose:        bool | *false
	AddressMode:   *"auto" | "alloc" | "driver" | "host"
	Advertise:     string | *""
	Interval:      int64 & >=(1 * time.Second)
	Timeout:       int64 & >=(1 * time.Second)
	InitialStatus: *"" | "passing" | "warning" | "critical"
	Notes:         string | *""
	TLSServerName: string | *""
	TLSSkipVerify: bool | *false
	Header: {[string]: [...string]} | *null
	Method:                 string | *""
	CheckRestart:           #CheckRestart | *null
	GRPCService:            string | *""
	GRPCUseTLS:             bool | *false
	TaskName:               string
	SuccessBeforePassing:   int | *0
	FailuresBeforeCritical: int | *0
	FailuresBeforeWarning:  int | *0
	Body:                   string | *""
	OnUpdate:               *"require_healthy" | "ignore_warnings" | "ignore"

	if Type == "script" {
		SuccessBeforePassing:   0
		FailuresBeforeCritical: 0
		FailuresBeforeWarning:  0
	}

	if Type != "script" {
		Command: ""
		Args:    null
	}

	if Type != "grpc" {
		GRPCService: ""
		GRPCUseTLS:  false
	}

	if Type == "http" {
		Protocol: *"http" | "https"
	}

	if Type != "http" {
		Header:   null
		Body:     ""
		Path:     ""
		Protocol: ""
	}

	if !(Protocol == "https" || (Type == "grpc" && GRPCUseTLS)) {
		TLSServerName: ""
		TLSSkipVerify: false
	}
}

// Service represents a Nomad job-submitters view of a Consul or Nomad service.
// https://developer.hashicorp.com/nomad/docs/job-specification/service
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/services.go#L231-L260
#Service: {
	serviceName=Name: string
	Tags: [...string] | *null
	CanaryTags: [...string] | *null
	EnableTagOverride: bool | *false
	PortLabel:         string | *""
	AddressMode:       string | *""
	Address:           string | *""
	Checks: [...#ServiceCheck & {
		Name:     string | *"service: \(strconv.Quote(serviceName)) check"
		TaskName: serviceTaskName
	}] | *null
	CheckRestart: #CheckRestart | *null
	Meta: {[string]: string} | *null
	CanaryMeta: {[string]: string} | *null
	TaggedAddresses: {[string]: string} | *null
	serviceTaskName=TaskName: string
	OnUpdate:                 *"require_healthy" | "ignore_warnings" | "ignore"
	Identity:                 #WorkloadIdentity | *null
	Weights:                  #ServiceWeights | *null

	Provider: *"consul" | "nomad"
	Kind:     string | *""

	if Provider != "consul" {
		Weights: null
		Checks: [...#ServiceCheck & {
			Type:                   "http" | "tcp"
			InitialStatus:          ""
			SuccessBeforePassing:   0
			FailuresBeforeCritical: 0
			FailuresBeforeWarning:  0
		}] | *null
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
