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

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/resources.go#L11-L29
#Resources: {
	// CPU is the CPU required to run this task in MHz.
	CPU:   (uint & >=1) | *100
	Cores: uint | *0
	// MemoryMB is the memory required to run this task in MiB.
	MemoryMB:     (uint & >=10) | *300
	MemoryMaxMB?: uint & >=MemoryMB
	Networks: [...#NetworkResource]
	SecretsMB?: uint
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/resources.go#L147-L153
#Port: {
	Label:           string
	Value?:          int
	To?:             int
	HostNetwork?:    string
	IgnoreCollision: bool | *false
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/resources.go#L155-L159
#DNSConfig: {
	Servers: [...string]
	Searches: [...string]
	Options: [...string]
}

// NetworkResource is used to describe required network
// resources of a given task.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/resources.go#L164-L182
#NetworkResource: {
	Mode:   string | *""
	Device: string | *""
	CIDR:   string | *""
	IP:     string | *""
	DNS:    #DNSConfig | *null
	ReservedPorts: [...#Port] | *null
	DynamicPorts: [...#Port] | *null
	Hostname: string | *""

	CNI: {
		Args: [string]: string
	} | *null

	// Deprecated.
	MBits: int | *null
}
