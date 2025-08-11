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

import "time"

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L98-L106
#RestartPolicy: {
	Interval:        int64
	Attempts:        uint
	Delay:           int64 | *(15 * time.Second)
	Mode:            *"fail" | "delay"
	RenderTemplates: bool | *false
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L649-L657
#DefaultServiceJobRestartPolicy: #RestartPolicy & {
	Delay:           15 * time.Second
	Attempts:        2
	Interval:        30 * time.Minute
	Mode:            "fail"
	RenderTemplates: false
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L661-L669
#DefaultBatchJobRestartPolicy: #RestartPolicy & {
	Delay:           15 * time.Second
	Attempts:        3
	Interval:        24 * time.Hour
	Mode:            "fail"
	RenderTemplates: false
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L496-L523
#TaskGroup: {
	Name:  string
	Count: uint
	Constraints: [...#Constraint] | *null
	Tasks: [...#Task]
	Volumes: [label=string]: #VolumeRequest & {Name: label}
	RestartPolicy: #RestartPolicy | *null
	EphemeralDisk: #EphemeralDisk | *null
	Update:        #UpdateStrategy | *null
	Migrate:       #MigrateStrategy | *null
	Networks: [...#NetworkResource] | *null
	Meta: {[string]: string} | *null
	Services: [...#Service] | *null
	ShutdownDelay: int64 | *0
	Scaling:       #ScalingPolicy | *null

	if Scaling == null {
		Count: uint | *1
	}
	if Scaling != null {
		Count: uint | *(Scaling.Min)
	}
}

_#TaskGroupWithDefaults: {
	X=in: {
		JobName: string
		JobType: "service" | "system" | "batch" | "sysbatch"
	}

	Y=out: #TaskGroup & {
		Services: [...(_#ServiceWithDefaults & {in: {
			JobName:   X.JobName
			GroupName: Y.Name
		}}).out] | *null

		Tasks: [...(_#TaskWithDefaults & {in: {
			JobName:   X.JobName
			GroupName: Y.Name
		}}).out]

		if (X.JobType == "service" || X.JobType == "system") {
			RestartPolicy: {
				for k, v in #RestartPolicy {"\(k)": v | *(#DefaultServiceJobRestartPolicy[k])}
			} | *null
		}
		if (X.JobType == "batch" || X.JobType == "sysbatch") {
			RestartPolicy: {
				for k, v in #RestartPolicy {"\(k)": v | *(#DefaultBatchJobRestartPolicy[k])}
			} | *null
		}
	}
}

// EphemeralDisk is an ephemeral disk object.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L364-L369
#EphemeralDisk: {
	Sticky:  bool | *false
	Migrate: bool | *false
	// SizeMB is the size of the ephemeral disk in MiB.
	SizeMB: uint | *300
}

// MigrateStrategy describes how allocations for a task group should be
// migrated between nodes (eg when draining).
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L391-L398
#MigrateStrategy: {
	MaxParallel:     uint | *1
	HealthCheck:     *"checks" | "task_states"
	MinHealthyTime:  int64 | *(10 * time.Second)
	HealthyDeadline: int64 | *(5 * time.Minute)
}

// VolumeRequest is a representation of a storage volume that a TaskGroup wishes to use.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L452-L464
#VolumeRequest: {
	Name:     string
	Type:     "host" | "csi"
	Source:   string
	ReadOnly: bool | *false
	Sticky:   bool | *false
	PerAlloc: bool | *false
}

// VolumeMount represents the relationship between a destination path in a task
// and the task group volume that should be mounted there.
// https://developer.hashicorp.com/nomad/docs/job-specification/volume_mount
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L472-L480
#VolumeMount: {
	Volume:          string
	Destination:     string
	ReadOnly:        bool | *false
	PropagationMode: *"private" | "host-to-task" | "bidirectional"
	SELinuxLabel:    string | *""
}

// LogConfig provides configuration for log rotation.
// https://developer.hashicorp.com/nomad/docs/job-specification/logs
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L716-L726
#LogConfig: {
	MaxFiles:      uint | *10
	MaxFileSizeMB: uint | *10
	Disabled:      bool | *false
	Enabled:       !Disabled
}

// Task is a single process in a task group.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L769-L808
#Task: {
	taskName=Name: string
	Driver:        string
	User:          string | *""
	Config: {[string]: _} | *null
	Constraints: [...#Constraint] | *null
	Env: {[string]: string} | *null
	Services: [...#Service & {
		Checks: [...{
			#ServiceCheck
			TaskName: taskName
		}] | *null
	}] | *null
	Resources:     #Resources | *null
	RestartPolicy: #RestartPolicy | *null
	Meta: {[string]: string} | *null
	LogConfig: #LogConfig | *null
	Vault:     #Vault | *null
	Templates: [...#Template] | *null
	VolumeMounts: [...#VolumeMount] | *null
	Leader:   bool | *false
	Identity: #WorkloadIdentity | *null
	Identities: [...#WorkloadIdentity] | *null
}

_#TaskWithDefaults: {
	X=in: {
		JobName:   string
		GroupName: string
	}

	out: #Task & {
		Services: [...(_#ServiceWithDefaults & {in: X})] | *null
	}
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L922-L927
#ChangeScript: {
	Command: string
	Args: [...string]
	Timeout:     int64 | *(5 * time.Second)
	FailOnError: bool | *false
}

// https://developer.hashicorp.com/nomad/docs/job-specification/template
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L944-L962
#Template: {
	{
		SourcePath:   string & !=""
		EmbeddedTmpl: ""
	} | {
		SourcePath:   ""
		EmbeddedTmpl: string & !=""
	}
	DestPath:      string
	ChangeMode:    "noop" | *"restart" | "signal" | "script"
	ChangeScript:  #ChangeScript | null
	ChangeSignal:  string
	Once:          bool | *false
	Splay:         int64 | *(5 * time.Second)
	Perms:         string | *"0644"
	LeftDelim:     string | *"{{"
	RightDelim:    string | *"}}"
	Envvars:       bool | *false
	ErrMissingKey: bool | *false

	if ChangeMode != "signal" {
		ChangeSignal: ""
	}
	if ChangeMode != "script" {
		ChangeScript: null
	}
}

// https://developer.hashicorp.com/nomad/docs/job-specification/vault
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L1017-L1027
#Vault: {
	Policies: [...string] | *null
	Role:                 string | *""
	Namespace:            string | *""
	Cluster:              string | *"default"
	Env:                  bool | *true
	DisableFile:          bool | *false
	ChangeMode:           "noop" | *"restart" | "signal"
	ChangeSignal:         string
	AllowTokenExpiration: bool | *false

	if ChangeMode != "signal" {
		ChangeSignal: ""
	}
}

// WorkloadIdentity is the jobspec block which determines if and how a workload
// identity is exposed to tasks.
// https://developer.hashicorp.com/nomad/docs/job-specification/identity
// https://github.com/hashicorp/nomad/blob/main/api/tasks.go#L1226-L1238
#WorkloadIdentity: {
	Name: string
	Audience: [...string] | *null
	ChangeMode:   *"noop" | "restart" | "signal"
	ChangeSignal: string
	Env:          bool | *false
	File:         bool | *false
	Filepath:     string | *""
	ServiceName:  string | *""
	TTL:          int64 | *0

	if ChangeMode != "signal" {
		ChangeSignal: ""
	}
	if !File {
		Filepath: ""
	}
}
